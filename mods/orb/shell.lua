-- shell

orb.shell = {
   new_env = function(user)
      local home = "/home/" .. user
      -- TODO: protected env: shouldn't be allowed to change USER
      return { PATH = "/bin", PROMPT = "${CWD} $ ", SHELL = "/bin/smash",
               CWD = home, HOME = home, USER = user,
               -- TODO: need a non-blocking read; look into posix.rpoll
               -- https://luaposix.github.io/luaposix/modules/posix.poll.html
               read = io.read, write = io.write
      }
   end,

   parse = function(f, env, command)
      local args = {}
      local tokens = orb.utils.split(command, " +")
      local executable_name = table.remove(tokens, 1)
      local t = table.remove(tokens, 1)
      while t do
         if(t == "<") then
            local file = f[orb.fs.normalize(tokens[1], env.CWD)]
            local lines = orb.utils.split(file, "\n")
            env.read = function() return table.remove(lines, 1) end
            break
         elseif(t == ">") then
            local target = table.remove(tokens, 1)
            local dirname, base = orb.fs.dirname(orb.fs.normalize(target, env.CWD))
            local dir = f[dirname]
            local contents = ""
            env.write = function(output)
               contents = contents .. output
               dir[base] = contents
            end
            break
         elseif(t == ">>") then
            local dirname, base = orb.fs.dirname(orb.fs.normalize(target, env.CWD))
            local dir = f[dirname]
            local contents = dir[base] or ""
            env.write = function(output)
               contents = contents .. output
               dir[base] = contents
            end
            break
         elseif(t == "|") then
            local env2 = orb.utils.shallow_copy(env)
            local buffer = {}
            env2.read = function()
               while #buffer == 0 do coroutine.yield() end
               return table.remove(buffer, 1)
            end
            env.write = function(output)
               table.insert(buffer, output)
            end
            local co = orb.process.spawn(f, env, table.concat(tokens, " "))
            break
         else
            table.insert(args, t)
         end
         t = table.remove(tokens, 1)
      end
      return executable_name, args
   end,

   exec = function(f, env, command)
      local env = orb.utils.shallow_copy(env)
      local executable_name, args = orb.shell.parse(f, env, command)

      for _, d in pairs(orb.utils.split(env.PATH, ":")) do
         local executable_path = d .. "/" .. executable_name
         local executable = f[orb.fs.normalize(executable_path, env.CWD)]
         if(executable) then
            local chunk = assert(loadstring(executable))
            setfenv(chunk, orb.shell.sandbox(env))
            return chunk(f, env, args)
         end
      end
      error(executable_name .. " not found.")
   end,

   pexec = function(f, env, command)
      return pcall(function() orb.shell.exec(f, env, command) end)
   end,

   sandbox = function(env)
      local read = function(...) return env.read(...) end
      local write = function(...) return env.write(...) end

      return { orb = { utils = orb.utils,
                       dirname = orb.fs.dirname,
                       normalize = orb.fs.normalize,
                       mkdir = orb.fs.mkdir,
                       exec = orb.shell.exec,
                       pexec = orb.shell.pexec,
                     },
               pairs = orb.utils.mtpairs,
               print = function(...)
                  -- print(...)
                  write(tostring(...)) write("\n") end,
               coroutine = { yield = coroutine.yield,
                             status = coroutine.status },
               io = { write = write, read = read },
               type = type,
               table = { concat = table.concat },
      }
   end,

   groups = function(f, user)
      local dir = f["/etc/groups"]
      local found = {}
      for group,members in orb.utils.mtpairs(dir) do
         if(type(members) == "table" and orb.utils.includes(members, user)) then
            table.insert(found, group)
         end
      end
      return found
   end,

   in_group = function(f, user, group)
      local group_dir = f.etc.groups[group]
      return group_dir and group_dir[user]
   end,
}

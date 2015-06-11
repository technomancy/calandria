-- shell

orb.shell = {
   new_env = function(user)
      local home = "/home/" .. user
      -- TODO: protected env: shouldn't be allowed to change USER
      return { PATH = "/bin", PROMPT = "${CWD} $ ", SHELL = "/bin/smash",
               CWD = home, HOME = home, USER = user,
      }
   end,

   -- This function does too much: it turns a command string into a tokenized
   -- list of arguments, but it also searches the argument list for stdio
   -- redirects and sets up the environment's read/write appropriately.
   parse = function(f, env, command)
      local args = {}
      local tokens = orb.utils.split(command, " +")
      local executable_name = table.remove(tokens, 1)
      local t = table.remove(tokens, 1)
      while t do
         if(t == "<") then
            env.IN = orb.fs.normalize(tokens[1], env.CWD)
            break
         elseif(t == ">") then
            local target = table.remove(tokens, 1)
            target = orb.fs.normalize(target, env.CWD)
            local dir, base = orb.fs.dirname(target)
            if(type(f[dir][base]) == "string") then f[dir][base] = "" end
            env.OUT = target
            break
         elseif(t == ">>") then
            local target = table.remove(tokens, 1)
            env.OUT = orb.fs.normalize(target, env.CWD)
            break
         -- elseif(t == "|") then
         --    -- TODO: support pipelines of arbitrary length
         --    -- TODO: IN and OUT as buffer tables?
         --    local env2 = orb.utils.shallow_copy(env)
         --    local buffer = {}
         --    env2.read = function()
         --       while #buffer == 0 do coroutine.yield() end
         --       return table.remove(buffer, 1)
         --    end
         --    env.write = function(output)
         --       table.insert(buffer, output)
         --    end
         --    local co = orb.process.spawn(f, env, table.concat(tokens, " "))
         --    break
         else
            table.insert(args, t)
         end
         t = table.remove(tokens, 1)
      end
      return executable_name, args
   end,

   -- Execute a command directly in the current coroutine. This is a low-level
   -- call; usually you want orb.process.spawn which creates it as a proper
   -- process.
   exec = function(f, env, command)
      local env = orb.utils.shallow_copy(env)
      local executable_name, args = orb.shell.parse(f, env, command)

      for _, d in pairs(orb.utils.split(env.PATH, ":")) do
         local executable_path = d .. "/" .. executable_name
         local executable = f[orb.fs.normalize(executable_path, env.CWD)]
         if(type(executable) == "string") then
            local chunk = assert(loadstring(executable))
            setfenv(chunk, orb.shell.sandbox(f, env))
            return chunk(f, env, args)
         end
      end
      error(executable_name .. " not found.")
   end,

   -- Like exec, but protected in a pcall.
   pexec = function(f, env, command)
      return pcall(function() orb.shell.exec(f, env, command) end)
   end,

   -- Set up the sandbox in which code runs. Need to avoid exposing anything
   -- that could allow security leaks.
   sandbox = function(f, env)
      local read = function(...) return orb.fs.read(f, env.IN) end
      local write = function(...) return orb.fs.write(f, env.OUT, ...) end

      return { orb = { utils = orb.utils,
                       dirname = orb.fs.dirname,
                       normalize = orb.fs.normalize,
                       mkdir = orb.fs.mkdir,
                       exec = orb.shell.exec,
                       pexec = orb.shell.pexec,
                       read = orb.utils.partial(orb.fs.read, f),
                       write = orb.utils.partial(orb.fs.write, f),
                       append = orb.fs.append,
                       reload = orb.fs.reloaders[f],
                     },
               pairs = orb.utils.mtpairs,
               print = function(...)
                  write(tostring(...)) write("\n") end,
               coroutine = { yield = coroutine.yield,
                             status = coroutine.status },
               io = { write = write, read = read },
               type = type,
               table = { concat = table.concat,
                         remove = table.remove,
                         insert = table.insert,
               },
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

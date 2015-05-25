-- shell

orb.shell = {
   new_env = function(user)
      local home = "/home/" .. user
      -- TODO: protected env: shouldn't be allowed to change USER
      return { PATH = "/bin", PROMPT = "${CWD} $ ", SHELL = "/bin/smash",
               CWD = home, HOME = home, USER = user,
               read = io.read, write = io.write
      }
   end,

   exec = function(f, env, command)
      local args = orb.utils.split(command, " ")
      local executable_name = table.remove(args, 1)
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

   pcall = function(f, env, command)
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
                       pcall = orb.shell.pcall,
                     },
               pairs = orb.utils.mtpairs,
               print = function(...) write(... .. "\n") end,
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

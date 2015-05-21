-- shell

orb.shell = {
   new_env = function(user)
      local home = "/home/" .. user
      -- TODO: protected env: shouldn't be allowed to change USER
      return { PATH = "/bin", PROMPT = "${CWD} $ ", SHELL = "/bin/smash",
               CWD = home, HOME = home, USER = user,
      }
   end,

   exec = function(raw_f, env, command, out)
      local args = orb.utils.split(command, " ")
      local executable_name = table.remove(args, 1)
      local f = orb.fs.protected_fs(raw_f, env.USER)
      for _, d in pairs(orb.utils.split(env.PATH, ":")) do
         local executable_path = d .. "/" .. executable_name
         local executable = orb.fs.find(f, d)[executable_name]
         if(executable) then
            local chunk = assert(loadstring(executable))
            setfenv(chunk, orb.shell.sandbox(out))
            return chunk(f, env, args)
         end
      end
      print(executable_name .. " not found.")
   end,

   sandbox = function(out)
      local printer = print
      if(out) then printer = function(str) table.insert(out, str) end end

      return { orb = { utils = orb.utils,
                       dirname = orb.fs.dirname,
                       normalize = orb.fs.normalize,
                       mkdir = orb.fs.mkdir,
                       find = orb.fs.find,
                       exec = orb.shell.exec
                     },
               pairs = pairs,
               print = printer,
               io = { write = io.write, read = io.read },
               type = type,
               table = { concat = table.concat },
      }
   end,

   groups = function(f, user)
      local dir = orb.fs.find(f, "/etc/groups")
      local found = {}
      for group,members in pairs(dir) do
         if(type(members) == "table" and orb.utils.includes(members, user)) then
            table.insert(found, group)
         end
      end
      return found
   end,

   in_group = function(f, user, group)
      local group_dir = orb.fs.find(f, "/etc/groups/" .. group)
      if(not group_dir) then return false end
      return group_dir[user]
   end,
}

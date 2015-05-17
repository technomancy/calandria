-- a fake lil' OS

orb = {}

-- utils

orb.utils = {
   split = function(str,div)
      if(div=='') then return {str} end
      local pos,res = 0,{}
      for st,sp in function() return string.find(str,div,pos,true) end do
         local str = string.sub(str,pos,st-1)
         if(str ~= "") then table.insert(res,str) end
         pos = sp + 1
      end
      table.insert(res,string.sub(str,pos))
      return res
   end,

   shallow_copy = function(orig)
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
         copy = {}
         for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
         end
      else -- number, string, boolean, etc
         copy = orig
      end
      return copy
   end,

   mod_dir = (minetest and minetest.get_modpath("orb")) or
      debug.getinfo(1,"S").source:sub(2, -9),

   interp = function(s, tab)
      return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
   end,
}

-- filesystem

orb.fs = {
   empty = function()
      return {_user = "root", _group = "root", _permissions = 493}
   end,

   mkdir = function(f, path, env)
      local dir, base = orb.fs.dirname(path)
      local parent = orb.fs.find(f, dir, env) or f
      -- if(not parent) then orb.fs.mkdir(f, dir, env) end
      parent[base] = {
         _user = parent._user,
         _group = parent._group,
         _permissions = parent._permissions,
      }
   end,

   dirname = function(path)
      local t = orb.utils.split(path, "/")
      local basename = t[#t]
      table.remove(t, #t)
      return "/" .. table.concat(t, "/"), basename
   end,

   seed = function(f, users)
      for _,d in pairs({"/etc", "/home", "/tmp", "/bin"}) do
         orb.fs.mkdir(f, d)
      end
      orb.fs.find(f, "/tmp")["_permissions"] = 511 -- 777 in decimal
      for _,u in pairs(users) do
         local home = "/home/" .. u
         orb.fs.mkdir(f, home)
         orb.fs.find(f, home)["_user"] = u
         orb.fs.find(f, home)["_group"] = u
      end
      for content_path, path in pairs({ls = "/bin/ls",
                                       mkdir = "/bin/mkdir",
                                       cd = "/bin/cd",
                                       cat = "/bin/cat",
                                       env = "/bin/env",
                                       mv = "/bin/mv",
                                       cp = "/bin/cp",
                                       rm = "/bin/rm",
                                       echo = "/bin/echo",
                                       smash = "/bin/smash",
                                       export = "/bin/export",
      }) do
         local dir, base = orb.fs.dirname(path)
         local resource_path = orb.utils.split(orb.utils.mod_dir, "/")
         table.remove(resource_path, #resource_path)
         local path = "/" .. table.concat(resource_path, "/") ..
            "/resources/" .. content_path
         local file = io.open(path, "r")
         orb.fs.find(f, "/" .. dir)[base] = file:read("*all")
         file:close()
      end
      return f
   end,

   find = function(f, path, env)
      if(env and env.CWD) then path = orb.fs.normalize(path, env.CWD) end
      if(path == "/") then return f end
      path = path:gsub("/$", "")
      local segments = orb.utils.split(path, "/")
      local final = table.remove(segments, #segments)
      for _,p in pairs(segments) do
         f = f[p]
      end
      return f[final]
   end,

   normalize = function(path,  cwd)
      if(path == ".") then return cwd end
      if(not path:match("^/")) then path = cwd .. "/" .. path end
      local final = {}
      for _,segment in pairs(orb.utils.split(path, "/")) do
         if(segment == "..") then
            table.remove(final, #final)
         else
            final[#final + 1] = segment
         end
      end
      return "/" .. table.concat(final, "/")
   end,

   permissions_for = function(f, filename, env)
      local file = orb.fs.find(f, filename, env)
      -- this kind of sucks; files currently don't have permissions, just dirs
      if(type(file) == "string") then
         file = orb.fs.find(f, filename .. "/..", env)
      end
      return file._permissions, file._user, file._group
   end,

   accessible = function(f, filename, env)
      -- bitwise operations were introduced in lua 5.2
      -- TODO: test this; it'd be a miracle if it actually worked
      local permissions, user, group = orb.fs.permissions_for(f, filename, env)
      if(user == env.USER and permissions % 8 > 3) then return true end
      permissions = (permissions - (permissions % 8)) / 8
      for _,ugroup in pairs(orb.shell.groups(env.USER)) do
         if(group == ugroup and permissions % 8 > 3) then return true end
      end
      permissions = (permissions - (permissions % 8)) / 8
      return permissions % 8 > 3
   end,
}

-- shell

orb.shell = {
   new_env = function(user)
      local home = "/home/" .. user
      return { PATH = "/bin", PROMPT = "${CWD} $ ", SHELL = "/bin/smash",
               CWD = home, HOME = home,
      }
   end,

   exec = function(f, env, command, out)
      args = orb.utils.split(command, " ")
      executable_name = table.remove(args, 1)
      for _, d in pairs(orb.utils.split(env.PATH, ":")) do
         local executable_path = d .. "/" .. executable_name
         executable = orb.fs.find(f, d)[executable_name]
         if(executable and orb.fs.accessible(f, executable_path, env)) then
            local chunk = assert(loadstring(executable))
            setfenv(chunk, orb.shell.sandbox(out))
            return chunk(f, env, args)
         end
      end
      print(executable_name .. " not found.")
   end,

   sandbox = function(out)
      if(out) then
         local printer = function(string) table.insert(out, string) end
      else
         local printer = print
      end

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

   -- TODO: look this up in the groups DB
   groups = function(user) return {user} end,}

-- interactively:
if(arg) then
   f1 = orb.fs.seed(orb.fs.empty(), {"technomancy", "buddy_berg", "zacherson"})
   e1 = orb.shell.new_env("technomancy")
   orb.shell.exec(f1, e1, "mkdir /tmp/hi")
   orb.shell.exec(f1, e1, "ls /tmp/hi")
   orb.shell.exec(f1, e1, "smash")
end

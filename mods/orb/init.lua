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

   mkdir = function(f, path, parent)
      first, rest = path:match("(/[^/]+)/(.*)")
      if(first) then
         orb.fs.mkdir(f[first:gsub("^/", "" )], rest, f)
      else
         parent = parent or {_user = "root", _group = "root",
                             _permissions = 493} -- 755 in decimal
         f[path:gsub("/", "")] = {
            _user = parent._user,
            _group = parent._group,
            _permissions = parent._permissions,
         }
      end
   end,

   dirname = function(path)
      local t = orb.utils.split(path, "/")
      local basename = t[#t]
      table.remove(t, #t)
      return table.concat(t, "/"), basename
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
      path = orb.fs.normalize(path, env and env.CWD)
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
}

-- shell

orb.shell = {
   new_env = function(user)
      local home = "/home/" .. user
      return { PATH = "/bin", PROMPT = "${CWD} $ ", SHELL = "/bin/smash",
               CWD = home, HOME = home,
      }
   end,

   exec = function(f, env, command)
      args = orb.utils.split(command, " ")
      executable_name = table.remove(args, 1)
      for _,d in pairs(orb.utils.split(env.PATH, ":")) do
         executable = orb.fs.find(f, d)[executable_name]
         if(executable) then
            local chunk = assert(loadstring(executable))
            -- TODO: sandbox with this:
            -- setfenv(chunk, process_env)
            return chunk(f, env, args)
         end
      end
      print(executable_name .. " not found.")
   end,
}

f1 = orb.fs.seed(orb.fs.empty(), {"technomancy", "buddy_berg", "zacherson"})
e1 = orb.shell.new_env("technomancy")
orb.shell.exec(f1, e1, "mkdir /tmp/hi")
orb.shell.exec(f1, e1, "mkdir /tmp/hi/ho") -- TODO: this is broken
orb.shell.exec(f1, e1, "ls /tmp/hi")

-- interactively:
-- orb.shell.exec(f1, e1, "smash")

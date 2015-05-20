-- fake lil filesystem
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

   add_to_group = function(f, user, group)
      assert(type(user) == "string" and type(group) == "string")
      local groups = orb.fs.find(f, "/etc/groups")
      groups[group] = groups[group] or {}
      table.insert(groups[group], user)
   end,

   seed = function(f, users)
      for _,d in pairs({"/etc", "/home", "/tmp", "/bin"}) do
         orb.fs.mkdir(f, d)
      end
      orb.fs.mkdir(f, "/etc/groups")
      orb.fs.find(f, "/tmp")["_permissions"] = 511 -- 777 in decimal
      for _,u in pairs(users) do
         local home = "/home/" .. u
         orb.fs.mkdir(f, home)
         orb.fs.add_to_group(f, u, u)
         orb.fs.add_to_group(f, u, "all")
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
         local path = "/" .. orb.utils.mod_dir .. "/resources/" .. content_path

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

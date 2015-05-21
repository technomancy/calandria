-- fake lil filesystem
orb.fs = {
   empty = function()
      return {_user = "root", _group = "root"}
   end,

   mkdir = function(f, path, env)
      local dir, base = orb.fs.dirname(path)
      local parent = orb.fs.find(f, dir, env) or f
      -- if(not parent) then orb.fs.mkdir(f, dir, env) end
      if(parent[base]) then return parent[base] end
      parent[base] = {
         _user = parent._user,
         _group = parent._group,
      }
      return parent[base]
   end,

   dirname = function(path)
      local t = orb.utils.split(path, "/")
      local basename = t[#t]
      table.remove(t, #t)
      return "/" .. table.concat(t, "/"), basename
   end,

   add_to_group = function(f, user, group)
      assert(type(user) == "string" and type(group) == "string")
      local group_dir = orb.fs.find(f, "/etc/groups/" .. group)
      if(not group_dir) then
         group_dir = orb.fs.mkdir(f, "/etc/groups/" .. group)
         group_dir._user = user
      end
      group_dir._group = group
      group_dir[user] = user
   end,

   seed = function(f, users)
      for _,d in pairs({"/etc", "/home", "/tmp", "/bin"}) do
         orb.fs.mkdir(f, d)
      end
      orb.fs.mkdir(f, "/etc/groups")
      orb.fs.find(f, "/tmp")["_group"] = "all"
      orb.fs.find(f, "/tmp")["_group_write"] = true
      orb.fs.find(f, "/bin")["_group"] = "all"
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
         assert(f, "Path not found: " .. path)
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

   owner = function(f, filename, env)
      local file = orb.fs.find(f, filename, env)
      if(type(file) == "string") then
         file = orb.fs.find(f, filename .. "/..", env)
      end
      return file._user, file._group, file._group_write
   end,

   readable = function(f, filename, env)
      local user, group = orb.fs.owner(f, filename, env)
      return user == env.USER or orb.shell.in_group(f, env.USER, group)
   end,

   writeable = function(f, filename, env)
      local user, group, group_write = orb.fs.owner(f, filename, env)
      return user == env.USER or
         (group_write and orb.shell.in_group(f, env.USER, group))
   end,
}

-- fake lil filesystem
orb.fs = {
   empty = function()
      return {_user = "root", _group = "all"}
   end,

   mkdir = function(f, path, env)
      local dir, base = orb.fs.dirname(path)
      local parent = f[orb.fs.normalize(dir, env and env.CWD)]

      if(not parent) then orb.fs.mkdir(f, dir, env) end
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

   add_user = function(f, user)
      local home = "/home/" .. user
      orb.fs.mkdir(f, home)
      orb.fs.add_to_group(f, user, user)
      orb.fs.add_to_group(f, user, "all")
      f[home]._user = user
      f[home]._group = user
   end,

   add_to_group = function(f, user, group)
      assert(type(user) == "string" and type(group) == "string")
      local group_dir = f[orb.fs.normalize("/etc/groups/" .. group)]

      if(not group_dir) then
         group_dir = orb.fs.mkdir(f, "/etc/groups/" .. group)
         group_dir._user = user
      end

      group_dir._group = group
      group_dir[user] = user
   end,

   copy_to_fs = function(f, fs_path, real_path)
      local dir, base = orb.fs.dirname(fs_path)
      local path = "/" .. orb.mod_dir .. "/resources/" .. real_path
      local file = io.open(path, "r")
      f["/"..dir][base] = file:read("*all")
      file:close()
   end,

   seed = function(f, users)
      for _,d in pairs({"/etc", "/home", "/tmp", "/bin"}) do
         orb.fs.mkdir(f, d)
         f[d]._group = "all"
      end

      orb.fs.mkdir(f, "/etc/groups")
      f["/tmp"]._group_write = "true"

      for _,user in pairs(users) do
         orb.fs.add_user(f, user)
      end

      for real_path, fs_path in pairs({ls = "/bin/ls",
                                       mkdir = "/bin/mkdir",
                                       cat = "/bin/cat",
                                       env = "/bin/env",
                                       mv = "/bin/mv",
                                       cp = "/bin/cp",
                                       rm = "/bin/rm",
                                       echo = "/bin/echo",
                                       smash = "/bin/smash",
                                       chmod = "/bin/chmod",
                                       chgrp = "/bin/chgrp",
                                       chown = "/bin/chown",
      }) do
         orb.fs.copy_to_fs(f, fs_path, real_path)
      end
      return f
   end,

   normalize = function(path, cwd)
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

   dir_meta = function(dir)
      return dir._user, dir._group, dir._group_write
   end,

   readable = function(f, dir, user)
      if(user == "root") then return true end
      local owner, group = orb.fs.dir_meta(dir)
      return owner == user or orb.shell.in_group(f, user, group)
   end,

   writeable = function(f, dir, user)
      if(user == "root") then return true end
      local owner, group, group_write = orb.fs.dir_meta(dir)
      return owner == user or
         (group_write and orb.shell.in_group(f, user, group))
   end,

   proxy = function(raw, user, raw_root)
      local descend = function(f, path, user)
         local target = f
         for _,d in pairs(orb.utils.split(path, "/")) do
            if(d == "") then break end
            -- readable here needs a fully-rooted fs to read groups
            assert(type(target) == "string" or
                      orb.fs.readable(raw_root, target, user),
                   ("Not readable: " .. path .. " d: " .. d))
            target = target[d]
         end
         return target
      end

      local unreadable = function(_k,v)
         return {_user = v._user, _group = v._group}
      end

      local f = {}
      local mt = {
         __index = function(_f, path)
            local target = descend(raw, path, user)
            if(type(target) == "table") then
               return orb.fs.proxy(target, user, raw_root)
            else
               return target
            end
         end,

         __newindex = function(f, path, content)
            local segments = orb.utils.split(path, "/")
            local base = table.remove(segments, #segments)
            local target = descend(raw, "/"..table.concat(segments,"/"), user)

            assert(orb.fs.writeable(raw_root, target, user),
                   "Not writeable: " .. path)
            target[base] = content
         end,

         __iterator = function(_f)
            assert(orb.fs.readable(raw_root, raw, user), "Not readable")
            local f = {}
            for k,v in pairs(raw) do
               if(type(v) == "string") then
                  f[k] = v
               elseif(type(v) == "table" and
                      orb.fs.readable(raw_root, v, user)) then
                  f[k] = orb.fs.proxy(v, user, raw_root)
               elseif(type(v) == "table") then
                  f[k] = unreadable(k, v)
               else
                  print("Unknown file type: " .. k)
                  print(v)
               end
            end
            return next,f,nil
         end,
      }
      setmetatable(f, mt)
      return f
   end,
}

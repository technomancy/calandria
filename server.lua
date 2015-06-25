-- this module is the glue tying together the orb mod (where the OS is
-- implemented) and game-engine-specific things like server nodes, diginet,
-- etc.

local diginet_dir = function(user, address)
   return "/home/" .. user .. "/diginet/" .. address
end

local session_name = function(player, term)
   return "session:" .. player .. ":" .. term
end

local create_io_fifos = function(env, fs, pos, address)
   orb.shell.exec(fs, env, "mkfifo " .. env.IN)
   fs[env.OUT] = diginet.partial({source=pos, destination=address,
                                  method="tty"}, {"body"})

end

local new_session_env = function(pos, server, player, user, address)
   local env = orb.shell.new_env(user)
   local fs = orb.fs.proxy(server.fs_raw, user, server.fs_raw)
   local dir = diginet_dir(user, address)
   orb.fs.mkdir(fs, dir, env)
   env.PROMPT = ""
   env.IN = dir .. "/in"
   env.OUT = dir .. "/out"

   create_io_fifos(env, fs, pos, address)

   server.sessions[session_name(player, address)] = env
   return env
end

-- reprogram luacontrollers remotely
local flash = function(pos_str, code)
   assert(type(code) == "string",
          "Tried to program luacontroller with" .. type(code))
   local pos = minetest.string_to_pos(pos_str)
   local node = minetest.registered_nodes[minetest.get_node(pos).name]
   print("Looking up node: " .. minetest.get_node(pos).name)
   return node.on_receive_fields(pos, "orb", {program = true, code = code})
end

local sandbox = { flash = flash, diginet = diginet,
                  digiline = function(pos, channel, msg)
                     digiline:receptor_send(pos, digiline.rules.default,
                                            channel, msg)
                  end,
                  minetest = { string_to_pos = string_to_pos,
                               pos_to_string = pos_to_string, }
}

calandria.server = {
   seed = function(fs)
      for real_path, fs_path in pairs({flash = "/bin/flash",
                                       digiline = "/bin/digiline",
                                       setports = "/bin/setports",
      }) do
         orb.fs.copy_to_fs(fs, fs_path, real_path,
                           minetest.get_modpath("calandria") .. "/resources/")
      end
   end,

   make = function(player, pos)
      -- TODO: set infotext
      local fs_raw = orb.fs.new_raw()
      local fs = orb.fs.proxy(fs_raw, "root", fs_raw)
      orb.fs.seed(fs, {player})
      calandria.server.seed(fs)
      local proc = orb.fs.mkdir(fs, "/proc/root")
      proc._group = "root"

      return { fs_raw = fs_raw, sessions = {} }
   end,

   find = function(pos)
      local server = calandria.server.placed[minetest.pos_to_string(pos)]
      if not server then
         print("Derp; no server. Creating a new one.") -- should never happen
         server = calandria.server.after_place(pos, {get_player_name =
                                                        function()
                                                           return player
         end})
      end
      return server
   end,

   path = minetest.get_worldpath() .. "/servers",

   load = function()
      print("Loading...")
      local file = io.open(calandria.server.path, "r")
      local contents = file and file:read("*all")
      if file then file:close() end
      if(file and contents ~= "") then
         calandria.server.placed = minetest.deserialize(contents)
         for pos_str,server in pairs(calandria.server.placed) do
            for session_name, env in pairs(server.sessions) do
               local fs = orb.fs.proxy(server.fs_raw, env.USER, server.fs_raw)
               local dir, base = orb.fs.dirname(session_name)
               local tty_address = orb.utils.split(base, ":")[3]
               create_io_fifos(env, fs, pos_str, tty_address)
            end
         end
      else
         return {}
      end
   end,

   save = function()
      for pos,server in pairs(calandria.server.placed) do
         orb.fs.strip_special(server.fs_raw)
      end
      local file = io.open(calandria.server.path, "w")
      file:write(minetest.serialize(calandria.server.placed))
      file:close()
   end,

   scheduler = function(pos, node, _active_object_count, _wider)
      local server = calandria.server.placed[minetest.pos_to_string(pos)]
      if server and server.fs_raw and server.fs_raw.proc then
         orb.process.scheduler(server.fs_raw)
      end
   end,

   -- callbacks
   after_place = function(pos, placer, _itemstack, _pointed)
      local server = calandria.server.make(placer:get_player_name(), pos)
      calandria.server.placed[minetest.pos_to_string(pos)] = server
      return server
   end,

   -- TODO: this crashes
   -- on_destruct = function(pos)
   --    table.remove(calandria.server.placed, minetest.pos_to_string(pos))
   -- end,

   on_tty = function(pos, packet)
      local server = calandria.server.find(pos)
      if(server) then
         local session_name = session_name(packet.player,
                                           minetest.pos_to_string(packet.source))
         local session = server.sessions[session_name]
         if(session) then
            -- TODO: cache proxies
            local fs = orb.fs.proxy(server.fs_raw, "root", server.fs_raw)
            local in_function = fs[session.IN]
            assert(in_function, "Missing session input file.")
            in_function(packet.body)
         else
            print("No session for " .. packet.player .. " on " ..
                     minetest.pos_to_string(pos))
         end
      else
         print("No server at " .. minetest.pos_to_string(pos))
      end
   end,

   on_login = function(pos, packet)
      local server = calandria.server.find(pos)
      if(server) then
         if(orb.shell.login(server.fs_raw, packet.user, packet.password)) then
            local env = new_session_env(pos, server, packet.player, packet.user,
                                        minetest.pos_to_string(packet.source))
            local fs = orb.fs.proxy(server.fs_raw, packet.player, server.fs_raw)

            orb.process.spawn(fs, env, "smash", sandbox)

            diginet.reply(packet, { method = "logged_in" })
         else
            diginet.reply(packet, { method = "tty", body = "Login failed." })
         end
      else
         print("No server at " .. minetest.pos_to_string(pos))
      end
   end,
}

calandria.server.placed = calandria.server.placed or {}

-- TODO: check to see if these have been loaded already:
-- if(not minetest.registered_items["mod:item"]) then ...
minetest.register_on_shutdown(calandria.server.save)

minetest.register_node("calandria:server", {
                          description = "server",
                          drawtype = "nodebox",
                          paramtype = "light",
                          paramtype2 = 'facedir',
                          node_box = {
                             type = "fixed",
                             fixed = {
                                {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
                             },
                          },
                          tiles =
                             {'cal_server_side.png', 'cal_server_side.png',
                              'cal_server_side.png', 'cal_server_side.png',
                              'cal_server_side.png', 'cal_server_front.png'},
                          groups = {dig_immediate = 2},
                          diginet = { tty = calandria.server.on_tty,
                                      login = calandria.server.on_login,
                          },
                          after_place_node = calandria.server.after_place,
                          on_destruct = calandria.server.on_destruct,
})

minetest.register_abm({
      nodenames = {"calandria:server"},
      interval = 1,
      chance = 1,
      action = calandria.server.scheduler,
})

calandria.server.load()

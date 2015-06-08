-- this module is the glue tying together the orb mod (where the OS is
-- implemented) and game-engine-specific things like server nodes, diginet,
-- etc.

local new_session = function(pos, server, player, tty)
   local env = orb.shell.new_env(player)
   env.PROMPT = ""
   local buffer = {}
   env.write = function(output)
      coroutine.yield()
      diginet.send({ source=pos, destination=tty,
                     method="tty", body=output })
   end
   env.read = function()
      while #buffer == 0 do coroutine.yield() end
      return table.remove(buffer, 1)
   end
   env.buffer_input = function(x)
      table.insert(buffer, x)
   end
   server.sessions[player] = env
   return env
end

calandria.server = {
   make = function(player, pos)
      local fs_raw = orb.fs.empty()
      local fs = orb.fs.proxy(fs_raw, "root", fs_raw)
      orb.fs.seed(fs, {player})
      local proc = orb.fs.mkdir(fs, "/proc/root")
      proc._group = "root"

      orb.process.spawn(fs, orb.shell.new_env("root"), "digi --daemon")
      orb.process.restore_digi(fs, orb.shell.new_env("root"), pos)

      return { fs = fs_raw, sessions = {} }
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
      if(file) then
         for k,fs in pairs(minetest.deserialize(file:read("*all"))) do
            print("Loading server at " .. k)
            calandria.server.placed[k] = { fs = fs, sessions = {} }
            orb.process.restore_digi(orb.fs.proxy(fs, "root", fs),
                                     orb.shell.new_env("root"),
                                     minetest.string_to_pos(k))
         end
         file:close()
      else
         return {}
      end
   end,

   save = function()
      print("Saving " .. orb.utils.size(calandria.server.placed))
      local file = io.open(calandria.server.path, "w")
      local filesystems = {}
      for k,v in pairs(calandria.server.placed) do
         print("Saving server at " .. k)
         orb.fs.strip_special(v.fs)
         filesystems[k] = v.fs
      end
      file:write(minetest.serialize(filesystems))
      file:close()
   end,

   scheduler = function(pos, node, _active_object_count, _wider)
      local server = calandria.server.placed[minetest.pos_to_string(pos)]
      if server and server.fs and server.fs.proc then
         orb.process.scheduler(server.fs)
      end
   end,

   -- callbacks
   after_place = function(pos, placer, _itemstack, _pointed)
      local server = calandria.server.make(placer:get_player_name(), pos)
      calandria.server.placed[minetest.pos_to_string(pos)] = server
      return server
   end,

   on_destruct = function(pos)
      table.remove(calandria.server.placed, minetest.pos_to_string(pos))
   end,

   on_tty = function(pos, packet)
      local server = calandria.server.find(pos)
      if(server) then
         local session = server.sessions[packet.player]
         if(session) then
            session.buffer_input(value)
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
         local env = new_session(pos, server, packet.player, packet.source)
         local fs = orb.fs.proxy(server.fs, packet.player, server.fs)

         orb.process.spawn(fs, env, "smash")

         -- ignoring passwords for now woooooo
         diginet.reply(packet, { method = "logged_in" })
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

-- this module is the glue tying together the orb mod (where the OS is
-- implemented) and game-engine-specific things like server nodes, digilines,
-- etc.

calandria.server = {
   after_place = function(pos, placer, _itemstack, _pointed)
      local server = calandria.server.make(placer:get_player_name(), pos)
      calandria.server.placed[minetest.pos_to_string(pos)] = server
      return server
   end,

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

   session = function(pos, server, player, channel)
      local env = orb.shell.new_env(player)
      local buffer = {}
      env.write = function(output)
         coroutine.yield()
         digiline:receptor_send(pos, digiline.rules.default, channel, output)
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
   end,

   digiline_action = function(pos, node, channel, msg)
      -- TODO: fix for multiple users
      if(type(msg) == "string") then
         local value = msg
         local player = "singleplayer"
         local server = calandria.server.placed[minetest.pos_to_string(pos)]
         if not server then
            print("Derp; no server. Creating a new one.") -- should never happen
            server = calandria.server.after_place(pos, {get_player_name =
                                                           function()
                                                              return player
            end})
         end

         local session = server.sessions[player]
         if(not session) then
            local env = calandria.server.session(pos, server, player, channel)
            -- since the input is in another formspec field, the
            -- regular prompt makes no sense.
            env.PROMPT = ""
            local fs = orb.fs.proxy(server.fs, player, server.fs)
            local co = orb.process.spawn(fs, env, "smash")
         end
         server.sessions[player].buffer_input(value)
      end
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
                          -- sounds = default.node_sound_stone_defaults(),
                          digiline = {
                             receptor = {},
                             effector = {
                                action = calandria.server.digiline_action
                             },
                          },
                          after_place_node = calandria.server.after_place
                          -- TODO: remove on destruct
                          -- TODO: digiterms need to send destruct messages too
})

minetest.register_abm({
      nodenames = {"calandria:server"},
      interval = 1,
      chance = 1,
      action = calandria.server.scheduler,
})

calandria.server.load()

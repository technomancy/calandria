local key_for = function(p) return "p" .. p.x .. "-" .. p.y .. "-" .. p.z end

calandria.server = {
   placed = {},

   after_place = function(pos, placer, _itemstack, _pointed)
      calandria.server.placed[key_for(pos)] =
         calandria.server.make(placer:get_player_name())
   end,

   make = function(player)
      local fs = orb.fs.empty()
      orb.fs.seed(orb.fs.proxy(fs, "root", fs), {player})

      return { fs = fs, sessions = {} }
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
      if(type(msg) == "function") then
         local value = msg()
         local player = value.player
         local server = calandria.server.placed[key_for(pos)]
         if not server then print("derp, no server") return end

         if(value.code == "init") then
            local env = calandria.server.session(pos, server, player, channel)
            local fs = orb.fs.proxy(server.fs, player, server.fs)
            local co = orb.process.spawn(fs, env, "smash")
         elseif value.msg and value.msg ~= "" then
            server.sessions[player].buffer_input(value.msg)
         end
      end
   end,

   path = minetest.get_worldpath() .. "/servers",

   load = function()
      local file = io.open(calandria.server.path, "r")
      if(file) then
         for k,v in pairs(minetest.deserialize(file:read("*all"))) do
            print("Loading server "..k)
            calandria.server.placed[k] = { fs = v, sessions = {} }
         end
         file:close()
      else
         return {}
      end
   end,

   save = function()
      local file = io.open(calandria.server.path, "w")
      local filesystems = {}
      for k,v in pairs(calandria.server.placed) do
         print("Saving server"..k)
         filesystems[k] = v.fs
      end
      file:write(minetest.serialize(filesystems))
      file:close()
   end,

   scheduler = function(pos, node, _active_object_count, _wider)
      local server = calandria.server.placed[key_for(pos)]
      if server.fs and server.fs.proc then
         orb.process.scheduler(server.fs)
      end
   end,
}

placed = calandria.server.load()
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
                          groups = {cracky=3,level=1},
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

-- can't use tables as table keys; lame but understandable
local key_for = function(p) return "p" .. p.x .. "-" .. p.y .. "-" .. p.z end

calandria.server = {
   -- TODO: restarting the server clears this, so you have to place
   -- server blocks anew for each server cycle
   placed = {},

   after_place = function(pos, placer, _itemstack, _pointed)
      calandria.server.placed[key_for(pos)] =
         calandria.server.make(placer:get_player_name())
   end,

   make = function(player)
      local f = orb.fs.empty()
      orb.fs.seed(orb.fs.proxy(f, "root", f), {player})
      local fs = orb.fs.proxy(f, player, f)
      local envs = {}
      local owner = player
      envs[owner] = orb.shell.new_env(owner)

      return {
         exec = function(input, player)
            if(not envs[player]) then return "No account on this server." end

            local out = {}
            envs[player].write = function(x) table.insert(out, #out) end
            orb.shell.exec(fs, envs[player], input)
            return "$ " .. input .. "\n" .. table.concat(out, "\n") .. "\n\n"
         end,
      }
   end,

   digiline_action = function(pos, node, channel, msg)
      if(type(msg) == "function") then
         local value = msg()
         if not value.msg then return end
         print("Executing "..value.msg)
         local server = calandria.server.placed[key_for(pos)]
         local result = server.exec(value.msg, value.player)
         digiline:receptor_send(pos, digiline.rules.default, channel, result)
      end
   end,
}

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
})

-- can't use tables as table keys; lame but understandable
local key_for = function(p) return "p" .. p.x .. "-" .. p.y .. "-" .. p.z end

calandria.computer = {
   placed = {},

   after_place = function(pos, placer, _itemstack, _pointed)
      -- TODO: determine channel somehow
      calandria.computer.placed[key_for(pos)] =
         calandria.computer.make(placer:get_player_name())
   end,

   make = function(player)
      local fs = orb.fs.seed(orb.fs.empty(), {player})
      local envs = {}
      local owner = player
      envs[owner] = orb.shell.new_env(owner)

      return {
         exec = function(input, player)
            if(not envs[player]) then return "No account on this server." end

            local out = {}
            orb.shell.exec(fs, envs[player], input, out)
            return "$ " .. input .. "\n" .. table.concat(out, "\n") .. "\n\n"
         end
      }
   end,

   digiline_action = function(pos, node, channel, msg)
      if(type(msg) == "function") then
         local value = msg()
         if not value.msg then return end

         local computer = calandria.computer.placed[key_for(pos)]
         local result = computer.exec(value.msg, value.player)
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
                             {'cal_computer_side.png', 'cal_computer_side.png',
                              'cal_computer_side.png', 'cal_computer_side.png',
                              'cal_computer_side.png', 'cal_computer_front.png'},
                          groups = {cracky=3,level=1},
                          -- sounds = default.node_sound_stone_defaults(),
                          digiline = {
                             receptor = {},
                             effector = {
                                action = calandria.computer.digiline_action
                             },
                          },
                          after_place_node = calandria.computer.after_place
                          -- TODO: remove on destruct
})

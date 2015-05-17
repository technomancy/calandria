calandria.computer = {
   nodes = {},

   after_place = function(pos, placer, _itemstack, _pointed)
      local meta = minetest.get_meta(pos)
      meta:set_string('channel', '') -- start on an empty channel
      local node = minetest.get_node(pos)
      calandria.computer.nodes[node] =
         calandria.computer.make(player)
   end,

   make = function(player)
      local fs = orb.fs.seed(orb.fs.empty(), {player})
      local envs = {}
      local owner = player
      return {
         exec = function(input, player)
            envs[player] = envs[player] or orb.shell.new_env(player)

            local out = {}
            orb.shell.exec(fs, envs[player], input)
            return table.concat(out, "\n")
         end
      }
   end,

   digiline_action = function(pos, node, channel, msg)
      local meta = minetest.get_meta(pos);
      if channel ~= meta:get_string('channel') then return end

      local node = minetest.get_node(pos)
      local result = meta.computer.nodes[node].exec(msg.msg, msg.player)
      digiline:receptor_send(pos, digiline.rules.default,
                             meta:get_string('channel'), fields.input);
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

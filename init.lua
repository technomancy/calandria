minetest.register_on_joinplayer(function(player)
      player:set_physics_override({gravity = 0.2})
end)

calandria = calandria or {}

dofile(minetest.get_modpath("calandria").."/nodes.lua")
dofile(minetest.get_modpath("calandria").."/mapgen.lua")
dofile(minetest.get_modpath("calandria").."/server.lua")
dofile(minetest.get_modpath("calandria").."/terminal.lua")

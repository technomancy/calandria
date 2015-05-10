minetest.register_node("calandria:steel", {
	description = "Steel",
    drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	tiles = {"calandria_steel.png"},
	groups = {cracky=3,level=2},
})

minetest.register_node("calandria:bustedsteel", {
	description = "Steel (buggy)",
	tiles = {"calandria_steel.png"},
	paramtype = "light",
	groups = {cracky=3,level=2},
})

minetest.register_node("calandria:stairs", {
	description = "Stairs",
    drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
			{-0.5, 0, 0, 0.5, 0.5, 0.5},
		},
	},
	tiles = {"calandria_steel.png"},
	groups = {cracky=3,level=2},
})

minetest.register_node("calandria:glass", {
	description = "Glass",
	drawtype = "glasslike",
	tiles = {"calandria_glass.png", "calandria_glass_detail.png"},
	paramtype = "light",
	sunlight_propagates = true,
	groups = {cracky=3},
})

minetest.register_node("calandria:light", {
	description = "Light",
    drawtype = "allfaces_optional",
	tiles = {"calandria_light.png"},
	paramtype = "light",
	sunlight_propagates = true,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	light_source = 14,
})

minetest.register_tool("calandria:pick", {
	description = "Diamond Pickaxe",
	inventory_image = "default_tool_diamondpick.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level=3,
		groupcaps={
			cracky = {times={[1]=2.0, [2]=1.0, [3]=0.50}, uses=30, maxlevel=3},
		},
		damage_groups = {fleshy=5},
	},
})

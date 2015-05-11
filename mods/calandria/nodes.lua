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
    groups = {cracky=3,level=1},
})

minetest.register_node("calandria:duranium", {
    description = "Duranium",
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        },
    },
    tiles = {"calandria_duranium.png"},
    groups = {cracky=3,level=1},
})

minetest.register_node("calandria:tritanium", {
    description = "Tritanium",
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        },
    },
    tiles = {"calandria_tritanium.png"},
    groups = {cracky=3,level=1},
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
    groups = {cracky=3,level=1},
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

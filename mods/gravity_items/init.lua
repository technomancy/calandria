-- Gravity items
-- Little mod ßý Mg
-- License : WTFPL

gravity_items = {}

gravity_items.register_item = function(name, number)
    if not number or not name or not type(number) == "number" or not type(name) == "string" then
        minetest.log("error", "[gravity_items] Cannot register item without valid number nor valid name")
        return false
    end
    minetest.register_craftitem("gravity_items:"..name, {
        description = number.." gravity item",
        inventory_image = "gravity_items_" .. name .. ".png",
        on_use = function(itemstack, user, pointed_thing)
            user:set_physics_override({gravity = number})
            minetest.chat_send_player(user:get_player_name(), "Gravity set to " .. number)
        end
    })
end

gravity_items.items = {
    ["null"] = 0,
    ["dot_one"] = 0.1,
    ["dot_five"] = 0.5,
    ["one"] = 1,
    ["ten"] = 10
}

for name, number in pairs(gravity_items.items) do
    gravity_items.register_item(name, number)
end

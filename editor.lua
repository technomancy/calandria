-- a lame text editor. supports save/load to servers over diginet.

local formspec = function(server, path, body)
   local s = minetest.formspec_escape(server or "")
   local p = minetest.formspec_escape(path or "")
   local b = minetest.formspec_escape(body or "")
   print("form with body " .. b)
   return "size[8,10]" ..
      "field[0.5,0.5;3,1;server;server;" .. s .. "]" ..
      "field[0.5,1.5;3,1;path;path;" .. p .. "]" ..
      "textarea[0.5,2.5;7,7;body;;" .. b .. "]" ..
      "button[0.5,9.5;3,1;save;save]" ..
      "button[4.5,9.5;3,1;load;load]"
end

-- TODO: allow overriding user
local save_file = function(pos, fields, player)
   local packet = { method = "save_file", source = pos,
                    destination = fields.server,
                    path = fields.path, body = fields.body,
                    user = player, player = player, }
   diginet.send(packet)
end

local load_file = function(pos, fields, player)
   local packet = { method = "get_file", source = pos,
                    destination = fields.server,
                    path = fields.path, user = player, player = player, }
   diginet.send(packet)
end

-- callbacks

local on_construct = function(pos)
   local meta = minetest.get_meta(pos)
   meta:set_string("formspec", formspec("", "", ""))
end

local on_receive_fields = function(pos, _, fields, player)
   if(fields.quit) then return end
   local meta = minetest.get_meta(pos)
   print("FIELDS")
   print(minetest.serialize(fields))
   meta:set_string("formspec", formspec(fields.server, fields.path, fields.body))
   print("Setting formspec " ..formspec(fields.server, fields.path, fields.body))
   if(fields.save) then
      save_file(pos, fields, player:get_player_name())
   elseif(fields.load) then
      load_file(pos, fields, player:get_player_name())
   end
end

local on_file = function(pos, packet)
   local meta = minetest.get_meta(pos)
   meta:set_string("formspec", formspec(minetest.pos_to_string(packet.source),
                                        packet.path, packet.body))
   print("Received file: " .. packet.path)
end

minetest.register_node("calandria:editor", {
                          description = "Text Editor",
                          paramtype = "light",
                          paramtype2 = "facedir",
                          walkable = true,
                          tiles = {
                             "calandria_server_side.png",
                             "calandria_server_side.png",
                             "calandria_server_side.png",
                             "calandria_server_side.png",
                             "calandria_server_side.png",
                             "calandria_editor_front.png"
                          },
                          diginet = { file = on_file,},
                          groups = {dig_immediate = 2},
                          on_construct = on_construct,
                          on_receive_fields = on_receive_fields,
})

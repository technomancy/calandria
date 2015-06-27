-- a lame text editor. supports save/load to servers over diginet.

-- TODO: ${text} meta references don't work
local formspec = "size[8,10]" ..
   "field[0.5,0.5;3,1;server;server;${server}]" ..
   "field[0.5,1.5;3,1;path;path;${path}]" ..
   "textarea[0.5,2.5;7,7;body;;${body}]" ..
   "button[0.5,9.5;3,1;save;save]" ..
   "button[4.5,9.5;3,1;load;load]"

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
   meta:set_string("formspec", formspec)
end

local on_receive_fields = function(pos, _formname, fields, player)
   local meta = minetest.get_meta(pos)
   meta:set_string("server", fields.server)
   meta:set_string("path", fields.path)
   meta:set_string("body", fields.body)
   meta:set_string("formspec", formspec)
   if(fields.save) then
      save_file(pos, fields, player:get_player_name())
   elseif(fields.load) then
      load_file(pos, fields, player:get_player_name())
   end
end

local on_file = function(pos, packet)
   local meta = minetest.get_meta(pos)
   meta:set_string("server", packet.source)
   meta:set_string("path", packet.path)
   meta:set_string("body", packet.body)
   meta:set_string("formspec", formspec)
   print("Received file: " .. packet.path)
end

minetest.register_node("calandria:editor", {
                          description = "Text Editor",
                          paramtype = "light",
                          paramtype2 = "facedir",
                          walkable = true,
                          tiles = {
                             "terminal_top.png",
                             "digicode_side.png",
                             "digicode_side.png",
                             "digicode_side.png",
                             "digicode_side.png",
                             "terminal_front.png"
                          },
                          diginet = { file = on_file,},
                          groups = {dig_immediate = 2},
                          on_construct = on_construct,
                          on_receive_fields = on_receive_fields,
})

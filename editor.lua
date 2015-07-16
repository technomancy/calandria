-- a lame text editor. supports save/load to servers over diginet.

local formspec = function(server, path, user, password, body, modeline)
   local s = minetest.formspec_escape(server or "")
   local p = minetest.formspec_escape(path or "")
   local u = minetest.formspec_escape(user or "")
   local pw = minetest.formspec_escape(password or "")
   local b = minetest.formspec_escape(body or "")
   local m = minetest.formspec_escape(modeline or "")
   return "size[8,10]" ..
      "field[0.5,0.5;3,1;server;server;" .. s .. "]" ..
      "field[4,0.5;3,1;path;path;" .. p .. "]" ..
      "field[0.5,1.5;3,1;user;user;" .. u .. "]" ..
      "field[4,1.5;3,1;password;password;" .. pw .. "]" ..
      "textarea[0.5,2.5;7,7;body;;" .. b .. "]" ..
      "label[0,8.75;" .. m .. "]" ..
      "button[4.5,9.5;2,1;new;new]" ..
      "button[2.5,9.5;2,1;load;load]" ..
      "button[0.5,9.5;2,1;save;save]"
end

local set_modeline = function(pos, modeline)
   local meta = minetest.get_meta(pos)
   local server = meta:get_string("server")
   local path = meta:get_string("path")
   local user = meta:get_string("user")
   local password = meta:get_string("password")
   local body = meta:get_string("body")
   meta:set_string("formspec", formspec(server, path, user, password,
                                        body, modeline))
end

local save_file = function(pos, fields, player)
   local packet = { method = "save_file", source = pos,
                    destination = fields.server,
                    path = fields.path, body = fields.body,
                    user = fields.user, password = fields.password,
                    player = player, }
   local success, err = pcall(function() diginet.send(packet) end)
   if(not success) then set_modeline(pos, err) end
end

local load_file = function(pos, fields, player)
   local packet = { method = "get_file", source = pos,
                    destination = fields.server,
                    user = fields.user, password = fields.password,
                    path = fields.path, player = player, }
   local success, err = pcall(function() diginet.send(packet) end)
   if(not success) then set_modeline(pos, err) end
end

-- callbacks

local on_construct = function(pos)
   local meta = minetest.get_meta(pos)
   meta:set_string("formspec", formspec("", "", "", "", "", ""))
end

local on_receive_fields = function(pos, _, fields, player)
   if(fields.quit) then return end
   local meta = minetest.get_meta(pos)
   meta:set_string("server", fields.server)
   meta:set_string("path", fields.path)
   meta:set_string("user", fields.user)
   meta:set_string("password", fields.password)
   meta:set_string("body", fields.body)
   meta:set_string("formspec", formspec(fields.server, fields.path,
                                        fields.user, fields.password,
                                        fields.body))

   if(fields.save) then
      save_file(pos, fields, player:get_player_name())
   elseif(fields.load) then
      load_file(pos, fields, player:get_player_name())
   elseif(fields.new) then
      meta:set_string("formspec", formspec(fields.server, "",
                                           fields.user, fields,password))
   end
end

local on_file = function(pos, packet)
   local meta = minetest.get_meta(pos)
   meta:set_string("server", packet.server)
   meta:set_string("path", packet.path)
   meta:set_string("body", packet.body)
   local user = meta:get_string("user")
   local password = meta:get_string("password")
   meta:set_string("formspec", formspec(minetest.pos_to_string(packet.source),
                                        packet.path, user, password,
                                        packet.body))
   print("Received file: " .. packet.path)
end

local on_modeline = function(pos, packet)
   set_modeline(pos, packet.modeline)
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
                          diginet = { file = on_file, modeline = on_modeline},
                          groups = {dig_immediate = 2},
                          on_construct = on_construct,
                          on_receive_fields = on_receive_fields,
})

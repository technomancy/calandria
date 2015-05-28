-- Taken from digipad mod, but trimmed down to just the interactive terminal

digipad = {}

-- ================
-- Variable declarations
-- ================

digipad.term_base_chan = "tty"
digipad.term_def_chan = "1"

digipad.terminal_size = {10, 8}

digipad.formspec =
   "size[" .. digipad.terminal_size[1] .. "," .. digipad.terminal_size[2] ..
   "]" .. "field[0," .. digipad.terminal_size[2] .. ";" ..
   digipad.terminal_size[1] .. ",1;input;;]"

-- ================
-- Function declarations
-- ================

digipad.set_channel = function(pos, new_channel)
   local meta = minetest.env:get_meta(pos)
   meta:set_string("channel", new_channel)
end

digipad.help = function(pos)  -- print help text
   digipad.new_line(pos, "Commands preceded with a / go to the")
   digipad.new_line(pos, "terminal. All others are sent along the digiline.")
   digipad.new_line(pos, "Commands are:   /clear  /help  /channel")
end

digipad.delete_spaces = function(s)
   -- David Manura
   -- trim whitespace from both ends of string
   return s:find'^%s*$' and '' or s:match'^%s*(.*%S)'
end

digipad.clear = function(pos)
   local meta = minetest.env:get_meta(pos)
   meta:set_string("formspec", digipad.formspec) -- reset to default
   meta:set_int("lines", 0)  -- start at the top of the screen again
end

digipad.parse_cmd = function(pos, cmd)
   if cmd == "clear" then
      digipad.clear(pos)
   elseif cmd == "help" then
      digipad.help(pos)
      -- If cmd _starts_with_ "channel", since we need an argument too.
   elseif string.sub(cmd, 1, 7) == "channel" then
      raw_arg = string.sub(cmd, 8) -- Cut "channel" out
      arg = digipad.delete_spaces(raw_arg)
      if (arg ~= nil) and (arg ~= "") then
         digipad.set_channel(pos, digipad.term_base_chan .. arg)
         digipad.new_line(pos, "Channel set to "..digipad.term_base_chan .. arg)
      else -- no argument
         digipad.new_line(pos, "Example: ''/channel 2'' will change")
         digipad.new_line(pos, "the channel to ''tty2'' ")
      end
   else
      digipad.new_line(pos, cmd .. ": command not found")
   end
end

local on_digiline_receive = function (pos, node, channel, msg)
   if(msg == "") then -- form-feed is typically used to clear screen
      digipad.clear(pos)
   else
      digipad.new_line(pos, msg)
   end
end

digipad.new_line = function(pos, text)
   local max_chars = digipad.terminal_size[1] * 8
   local max_lines = digipad.terminal_size[2] * 4
   local meta = minetest.env:get_meta(pos)
   local lines = meta:get_int("lines")

   -- clear screen before printing the line - so it's never blank
   if lines > max_lines then
      digipad.clear(pos)
      lines = meta:get_int("lines") -- update after clear
   end

   local formspec = meta:get_string("formspec")
   local offset = lines / 8
   local line = text:sub(1, max_chars)
   local new_formspec = formspec .. "label[0," .. offset .. ";" .. line .. "]"
   meta:set_string("formspec", new_formspec)
   lines = lines + 1
   meta:set_int("lines", lines)
   -- TODO: preserve input upon text insertion
   meta:set_string("formspec", new_formspec)

   -- If not all could be printed, recurse on the rest of the string
   if string.len(text) > max_chars then
      text = string.sub(text,max_chars)
      digipad.new_line(pos, text)
   end
end

digipad.on_construct = function(pos)
   local meta = minetest.env:get_meta(pos)
   meta:set_string("formspec", digipad.formspec)
   meta:set_string("Infotext", "Terminal")
   meta:set_int("lines", 0)
   -- set default channel (base + default extension) :
   meta:set_string("channel", digipad.term_base_chan .. digipad.term_def_chan)

   digipad.new_line(pos, "/help for help")  -- print welcome text
end

digipad.on_receive_fields = function(pos, formname, fields, sender)
   local meta = minetest.env:get_meta(pos)
   local text = fields.input
   local channel = meta:get_string("channel")
   if text ~= nil then
      digipad.new_line(pos, "> " .. text)

      if string.sub(text,1,1) == "/" then  -- command is for terminal
         text = string.sub(text, 2) -- cut off first char
         digipad.parse_cmd(pos, text)
      else
         digiline:receptor_send(pos, digiline.rules.default, channel, text)
      end
   end
   -- TODO: don't close terminal when enter is pressed
end

minetest.register_node("digipad:terminal", {
                          description = "Interactive Terminal",
                          paramtype = "light",
                          paramtype2 = "facedir",
                          sunlight_propagates = true,
                          walkable = true,
                          drawtype = "nodebox",
                          selection_box = {
                             type = "fixed",
                             fixed = {
                                {-0.5, -0.5, -0.5, 0.5, -0.3, 0}, -- Keyboard
                                {-0.5, -0.5, 0, 0.5, 0.5, 0.5}, --Screen
                             }
                          },
                          node_box = {
                             type = "fixed",
                             fixed = {
                                {-0.5, -0.5, -0.5, 0.5, -0.3, 0}, -- Keyboard
                                {-0.5, -0.5, 0, 0.5, 0.5, 0.5}, --Screen
                             }
                          },
                          tiles = {
                             "terminal_top.png",
                             "digicode_side.png",
                             "digicode_side.png",
                             "digicode_side.png",
                             "digicode_side.png",
                             "terminal_front.png"
                          },
                          digiline =
                             {
                                receptor={},
                                effector = {
                                   action = on_digiline_receive
                                },
                             },
                          groups = {dig_immediate = 2},
                          on_construct = digipad.on_construct,
                          on_receive_fields = digipad.on_receive_fields,
})

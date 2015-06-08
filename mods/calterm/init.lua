-- Taken from digipad mod, but trimmed down to just the interactive terminal.
-- Further changes include making it to work with higher-level diginet
-- functionality instead of just digilines, increasing the size, and fixing
-- the interaction model so the window stays up.

local terminal_size = {10, 8}

local split = function(str,div)
   if(div=='') then return {str} end
   if(div==str) then return {} end
   local pos,res = 0,{}
   for st,sp in function() return str:find(div,pos) end do
      local str = string.sub(str,pos,st-1)
      if(str ~= "") then table.insert(res,str) end
      pos = sp + 1
   end
   table.insert(res,string.sub(str,pos))
   return res
end

calterm = {
   formspec =
      "size[" .. terminal_size[1] .. "," .. terminal_size[2] .. "]" ..
      "field[0,"..terminal_size[2].. ";" .. terminal_size[1] .. ",1;input;;]",

   -- commands

   help = function(pos)  -- print help text
      calterm.new_line(pos, "Commands preceded with a / go to the terminal.")
      calterm.new_line(pos, " All others are sent over diginet.")
      calterm.new_line(pos, "Commands are:   /clear /help /login")
   end,

   clear = function(pos)
      local meta = minetest.env:get_meta(pos)
      meta:set_string("formspec", calterm.formspec) -- reset to default
      meta:set_int("lines", 0)  -- start at the top of the screen again
   end,

   login = function(pos, args)
      local dest, user, password = unpack(args)
      diginet.send({ source = pos, destination = dest, method = "login",
                     user = user, password = password })
   end,

   -- internals

   parse_cmd = function(pos, cmd)
      local tokens = split(cmd, " +")
      if cmd == "clear" then
         calterm.clear(pos)
      elseif cmd == "help" then
         calterm.help(pos)
      elseif tokens[1] == "login" then
         table.remove(tokens, 1)
         calterm.login(pos, tokens)
      else
         calterm.new_line(pos, cmd .. ": command not found")
      end
   end,

   new_line = function(pos, text)
      local max_chars = calterm.terminal_size[1] * 8
      local max_lines = calterm.terminal_size[2] * 4
      local meta = minetest.env:get_meta(pos)
      local lines = meta:get_int("lines")

      -- clear screen before printing the line - so it's never blank
      if lines > max_lines then
         calterm.clear(pos)
         lines = meta:get_int("lines") -- update after clear
      end

      local formspec = meta:get_string("formspec")
      local offset = lines / 4
      local line = text:sub(1, max_chars)
      local new_formspec = formspec.."label[0,"..offset..";"..line.."]"
      meta:set_string("formspec", new_formspec)
      local lines_split = split(text, "\n")
      lines = lines + #lines_split
      meta:set_int("lines", lines)
      -- TODO: preserve input upon text insertion
      meta:set_string("formspec", new_formspec)

      -- If not all could be printed, recurse on the rest of the string
      if string.len(text) > max_chars then
         text = string.sub(text,max_chars)
         calterm.new_line(pos, text)
      end
   end,

   -- callbacks

   on_construct = function(pos)
      local meta = minetest.env:get_meta(pos)
      meta:set_string("formspec", calterm.formspec)
      meta:set_string("Infotext", "Terminal")
      meta:set_int("lines", 0)

      calterm.new_line(pos, "/help for help")  -- print welcome text
   end,

   on_receive_fields = function(pos, formname, fields, sender)
      local meta = minetest.env:get_meta(pos)
      local text = fields.input

      if text ~= nil then
         calterm.new_line(pos, "> " .. text)
         local session_dest = meta:get_string("session_" .. sender)

         if string.sub(text,1,1) == "/" then  -- command is for terminal
            calterm.parse_cmd(pos, string.sub(text, 2))
         elseif(session_dest) then
            local dest = meta:get_string("session_" .. sender)
            diginet.send({ source = minetest.pos_to_string(pos),
                           destination = dest, method = "tty", body = text })
         else
            calterm.new_line(pos, "Not logged in; try /login SERVER USER PASSWORD")
         end
      end
      -- TODO: don't close terminal when enter is pressed
   end,

   on_tty = function(pos, packet)
      calterm.new_line(pos, packet.body)
   end,

   on_logged_in = function(pos, packet)
      local meta = minetest.env:get_meta(pos)
      meta:set_string("session_" .. packet.user)
   end,
}

minetest.register_node("calterm:terminal", {
                          description = "Interactive Terminal",
                          paramtype = "light",
                          paramtype2 = "facedir",
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
                          diginet = { tty = calterm.on_tty,
                                      logged_in = calterm.on_logged_in,
                          },
                          groups = {dig_immediate = 2},
                          on_construct = calterm.on_construct,
                          on_receive_fields = calterm.on_receive_fields,
})

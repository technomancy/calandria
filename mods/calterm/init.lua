-- Taken from digipad mod, but trimmed down to just the interactive terminal.
-- Further changes include making it to work with higher-level diginet
-- functionality instead of just digilines, increasing the size, and fixing
-- the interaction model so the window stays up. (hopefully)

-- Diginet Flow

-- 1. sends a method="login" packet with user/password fields to start session
-- 2. receives method="logged_in", associates source address with player name
-- 3. sends method="tty" with body field for input
-- 4. receives method="tty" with body field for output

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
      calterm.new_line(pos, "All others are sent over diginet.")
      calterm.new_line(pos, "You'll need to login to a server")
      calterm.new_line(pos, "before you can send any commands.")
      calterm.new_line(pos, "Commands are:   /clear /help /login")
   end,

   clear = function(pos)
      local meta = minetest.env:get_meta(pos)
      meta:set_string("formspec", calterm.formspec) -- reset to default
      meta:set_int("lines", 0)  -- start at the top of the screen again
   end,

   login = function(pos, player, args)
      local dest, user, password = unpack(args)
      dest = "(-13,1,-12)"
      user = "singleplayer"
      diginet.send({ source = pos, destination = dest, method = "login",
                     player = player, user = user, password = password })
   end,

   -- internals

   parse_cmd = function(pos, player, cmd)
      local tokens = split(cmd, " +")
      if cmd == "clear" then
         calterm.clear(pos)
      elseif cmd == "help" then
         calterm.help(pos)
      elseif tokens[1] == "login" then
         table.remove(tokens, 1)
         calterm.login(pos, player, tokens)
      else
         calterm.new_line(pos, cmd .. ": command not found")
      end
   end,

   new_line = function(pos, text)
      local max_chars = terminal_size[1] * 8
      local max_lines = (terminal_size[2] * 4) - 1
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
      if text:len() > max_chars then
         text = text:sub(max_chars)
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
      local player = sender:get_player_name()

      if text ~= nil then
         calterm.new_line(pos, "> " .. text)
         local session_dest = meta:get_string("session_" .. player)
         if text:sub(1,1) == "/" then  -- command is for terminal
            calterm.parse_cmd(pos, player, text:sub(2))
         elseif(session_dest ~= "") then
            diginet.send({ source = pos, destination = session_dest,
                           player = player, method = "tty", body = text })
         else
            calterm.new_line(pos, "Not logged in, try /login SERVER USER PASSWORD")
         end
      end
      -- TODO: don't close terminal when enter is pressed
   end,

   on_tty = function(pos, packet)
      calterm.new_line(pos, packet.body)
   end,

   on_error = function(pos, packet)
      calterm.new_line(pos, "! " .. packet.body)
   end,

   on_logged_in = function(pos, packet)
      local meta = minetest.env:get_meta(pos)
      meta:set_string("session_" .. packet.player,
                      minetest.pos_to_string(packet.source))
      calterm.new_line(pos, "Logged in.")
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
                                      error = calterm.on_error
                          },
                          groups = {dig_immediate = 2},
                          on_construct = calterm.on_construct,
                          on_receive_fields = calterm.on_receive_fields,
})

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

local split = function(orig,div)
   if(div=='') then return {orig} end
   if(div==orig) then return {} end
   local pos,res = 0,{}
   for st,sp in function() return orig:find(div,pos) end do
      local str = string.sub(orig,pos,st-1)
      if(str ~= "") then table.insert(res,str) end
      pos = sp + 1
   end
   table.insert(res,string.sub(orig,pos))
   return res
end

calandria = calandria or {}

calandria.term = {
   formspec =
      "size[" .. terminal_size[1] .. "," .. terminal_size[2] .. "]" ..
      "field[0.5,".. (terminal_size[2] - 0.5) .. ";" .. (terminal_size[1] - 0.5) ..
      ",0.5;input;;]" ..
      "button[" .. terminal_size[1] - 1 .. "," .. (terminal_size[2] - 0.5).. ";" ..
      "1,0.5;enter;enter]",

   -- commands

   help = function(pos)  -- print help text
      calandria.term.new_line(pos, "Commands starting with an = go to the terminal.")
      calandria.term.new_line(pos, "All others are sent over diginet.")
      calandria.term.new_line(pos, "You'll need to login to a server")
      calandria.term.new_line(pos, "before you can send any commands.")
      calandria.term.new_line(pos, "Commands are:   =clear =help =login")
   end,

   clear = function(pos)
      local meta = minetest.get_meta(pos)
      meta:set_string("formspec", calandria.term.formspec) -- reset to default
      meta:set_int("lines", 0)  -- start at the top of the screen again
   end,

   login = function(pos, player, args)
      local dest, user, password = unpack(args)

      diginet.send({ source = pos, destination = dest, method = "login",
                     player = player:get_player_name(), user = user,
                     password = password })
   end,

   -- internals

   parse_cmd = function(pos, player, cmd)
      local tokens = split(cmd, " +")
      if cmd == "clear" then
         calandria.term.clear(pos)
      elseif cmd == "help" then
         calandria.term.help(pos)
      elseif tokens[1] == "login" then
         table.remove(tokens, 1)
         calandria.term.login(pos, player, tokens)
      else
         calandria.term.new_line(pos, cmd .. ": command not found")
      end
   end,

   new_line = function(pos, text)
      local max_chars = terminal_size[1] * 8
      local max_lines = (terminal_size[2] * 4) - 3
      local meta = minetest.get_meta(pos)
      local lines = meta:get_int("lines")

      -- clear screen before printing the line - so it's never blank
      if lines > max_lines then
         calandria.term.clear(pos)
         lines = meta:get_int("lines") -- update after clear
      end

      local formspec = meta:get_string("formspec")
      local offset = lines / 4
      local line = text:sub(1, max_chars)
      local new_formspec = formspec.."label[0,"..offset..";"..
         minetest.formspec_escape(line) .."]"
      meta:set_string("formspec", new_formspec)
      local lines_split = split(text, "\n")
      lines = lines + #lines_split
      meta:set_int("lines", lines)
      -- TODO: preserve input upon text insertion
      -- may actually be impossible in minetest?
      meta:set_string("formspec", new_formspec)

      -- If not all could be printed, recurse on the rest of the string
      if text:len() > max_chars then
         text = text:sub(max_chars)
         calandria.term.new_line(pos, text)
      end
   end,

   -- callbacks

   on_construct = function(pos)
      local meta = minetest.get_meta(pos)
      meta:set_string("formspec", calandria.term.formspec)
      meta:set_string("Infotext", "Terminal")
      meta:set_int("lines", 0)

      calandria.term.new_line(pos, "type =help for help")  -- print welcome text
   end,

   on_receive_fields = function(pos, _, fields, player)
      local meta = minetest.get_meta(pos)
      local text = fields.input
      local player_name = player:get_player_name()

      if(text) then
         calandria.term.new_line(pos, "> " .. text)
         local session_dest = meta:get_string("session_" .. player_name)
         if text:sub(1,1) == "=" then  -- command is for terminal
            calandria.term.parse_cmd(pos, player, text:sub(2))
         elseif(session_dest ~= "") then
            diginet.send({ source = pos, destination = session_dest,
                           player = player_name, method = "tty", body = text })
         else
            calandria.term.new_line(pos, "Not logged in, try =login SERVER USER PASSWORD")
         end
      end
   end,

   on_tty = function(pos, packet)
      calandria.term.new_line(pos, packet.body)
   end,

   on_error = function(pos, packet)
      calandria.term.new_line(pos, "! " .. packet.body)
   end,

   on_logged_in = function(pos, packet)
      local meta = minetest.get_meta(pos)
      meta:set_string("session_" .. packet.player,
                      minetest.pos_to_string(packet.source))
      calandria.term.new_line(pos, "Logged in.")
   end,}

minetest.register_node("calandria:terminal", {
                          description = "Interactive Terminal",
                          paramtype = "light",
                          paramtype2 = "facedir",
                          walkable = true,
                          tiles = {
                             "calandria_server_side.png",
                             "calandria_server_side.png",
                             "calandria_server_side.png",
                             "calandria_server_side.png",
                             "calandria_server_side.png",
                             "calandria_terminal_front.png"
                          },
                          diginet = { tty = calandria.term.on_tty,
                                      logged_in = calandria.term.on_logged_in,
                                      error = calandria.term.on_error
                          },
                          groups = {dig_immediate = 2},
                          on_construct = calandria.term.on_construct,
                          on_receive_fields = calandria.term.on_receive_fields,
})

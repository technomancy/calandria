-- a fake lil' OS

orb = {}

-- utils

orb.utils = {
   split = function(str,div)
      if(div=='') then return {str} end
      local pos,res = 0,{}
      for st,sp in function() return string.find(str,div,pos,true) end do
         local str = string.sub(str,pos,st-1)
         if(str ~= "") then table.insert(res,str) end
         pos = sp + 1
      end
      table.insert(res,string.sub(str,pos))
      return res
   end,

   shallow_copy = function(orig)
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
         copy = {}
         for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
         end
      else -- number, string, boolean, etc
         copy = orig
      end
      return copy
   end,

   mod_dir = (minetest and minetest.get_modpath("orb")) or
      debug.getinfo(1,"S").source:sub(2, -9),

   interp = function(s, tab)
      return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
   end,

   includes = function(tab, val)
      for _,x in pairs(tab) do
         if(x == val) then return true end
      end
   end
}

dofile(orb.utils.mod_dir .. "fs.lua")
dofile(orb.utils.mod_dir .. "shell.lua")

-- interactively:
if(arg) then
   f1 = orb.fs.seed(orb.fs.empty(), {"technomancy", "buddy_berg", "zacherson"})
   e1 = orb.shell.new_env("technomancy")
   orb.shell.groups(f1, "technomancy")
   orb.shell.exec(f1, e1, "mkdir /tmp/hi")
   orb.shell.exec(f1, e1, "ls /tmp/hi")
   orb.shell.exec(f1, e1, "smash")
end

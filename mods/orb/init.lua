-- a fake lil' OS

orb = {}

-- utils

orb.utils = {
   split = function(str,div)
      if(div=='') then return {str} end
      if(div==str) then return {} end
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
   assert(orb.utils.mod_dir ~= "", "Could not determine mod dir.")
   f = orb.fs.empty()
   f1 = orb.fs.seed(orb.fs.proxy(f, "root"),
                    {"technomancy", "buddyberg", "zacherson"})
   e0 = orb.shell.new_env("root")
   e1 = orb.shell.new_env("technomancy")

   local t_groups = orb.shell.groups(f1, "technomancy")
   assert(orb.utils.includes(t_groups, "technomancy"))
   assert(orb.utils.includes(t_groups, "all"))

   orb.shell.exec(f1, e1, "mkdir /tmp/hi")
   orb.shell.exec(f1, e1, "ls /tmp/hi")
   orb.shell.exec(f1, e0, "ls /etc")

   assert(orb.fs.readable(f1, f1["/home/technomancy"], "technomancy"))
   assert(not orb.fs.readable(f1, f1["/home/zacherson"], "technomancy"))

   orb.shell.exec(f1, e1, "smash")
end

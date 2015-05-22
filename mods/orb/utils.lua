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

   interp = function(s, tab)
      return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
   end,

   includes = function(tab, val)
      for _,x in orb.utils.mtpairs(tab) do
         if(x == val) then return true end
      end
      return false
   end,

   mtpairs = function(tab)
      local mt = getmetatable(tab)
      if(mt) then
         return mt.__iterator(tab)
      else
         return pairs(tab)
      end
   end,
}

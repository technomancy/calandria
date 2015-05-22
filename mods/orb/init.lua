-- a fake lil' OS

orb = {
   mod_dir = (minetest and minetest.get_modpath("orb")) or
      debug.getinfo(1,"S").source:sub(2, -9),
}

dofile(orb.mod_dir .. "utils.lua")
dofile(orb.mod_dir .. "fs.lua")
dofile(orb.mod_dir .. "shell.lua")

-- interactively:
if(arg) then
   assert(orb.mod_dir ~= "", "Could not determine mod dir.")
   f = orb.fs.empty()
   f1 = orb.fs.seed(orb.fs.proxy(f, "root", f),
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

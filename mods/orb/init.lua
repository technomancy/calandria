-- a fake lil' OS

orb = {
   mod_dir = (minetest and minetest.get_modpath("orb")) or
      debug.getinfo(1,"S").source:sub(2, -9),
}

if(orb.mod_dir == "") then orb.mod_dir = "." end

dofile(orb.mod_dir .. "/utils.lua")
dofile(orb.mod_dir .. "/fs.lua")
dofile(orb.mod_dir .. "/shell.lua")
dofile(orb.mod_dir .. "/process.lua")
-- pp = dofile(orb.mod_dir .. "/PrettyPrint.lua")

-- interactively:
if(arg) then
   f = orb.fs.empty()
   f0 = orb.fs.seed(orb.fs.proxy(f, "root", f),
                    {"technomancy", "buddyberg", "zacherson"})
   f1 = orb.fs.proxy(f, "technomancy", f)
   e0 = orb.shell.new_env("root")
   e1 = orb.shell.new_env("technomancy")

   co = orb.process.spawn(f1, e1, "smash") -- Open an interactive shell
   coroutine.resume(co)

   -- tests
   t_groups = orb.shell.groups(f0, "technomancy")
   assert(orb.utils.includes(t_groups, "technomancy"))
   assert(orb.utils.includes(t_groups, "all"))
   assert(not orb.utils.includes(t_groups, "zacherson"))

   orb.shell.exec(f1, e1, "mkdir mydir")
   orb.shell.exec(f1, e1, "mkdir /tmp/hi")
   orb.shell.exec(f1, e1, "ls /tmp/hi")
   orb.shell.exec(f1, e0, "ls /etc")

   orb.shell.exec(f1, e1, "cd /tmp")
   orb.shell.exec(f1, e1, "cp /bin/ls ls2")
   orb.shell.exec(f1, e1, "ls")

   assert(orb.fs.readable(f0, f1["/home/technomancy"], "technomancy"))
   assert(orb.fs.readable(f0, f1["/bin"], "technomancy"))
   assert(orb.fs.readable(f0, f1["/bin"], "zacherson"))
   assert(orb.fs.writeable(f0, f1["/home/technomancy"], "technomancy"))
   assert(orb.fs.writeable(f0, f1["/tmp"], "technomancy"))

   -- assert(not orb.fs.writeable(f0, f1["/etc"], "technomancy"))
   -- assert(not orb.fs.writeable(f0, f1["/home/zacherson"], "technomancy"))
   -- assert(not orb.fs.readable(f0, f1["/home/zacherson"], "technomancy"))
end

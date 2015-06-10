-- a fake lil' OS

orb = orb or {
   mod_dir = (minetest and minetest.get_modpath("orb")) or
      debug.getinfo(1,"S").source:sub(2, -9):gsub("(/+)$", "/") }

if(orb.mod_dir == "") then orb.mod_dir = "." end

dofile(orb.mod_dir .. "/utils.lua")
dofile(orb.mod_dir .. "/fs.lua")
dofile(orb.mod_dir .. "/shell.lua")
dofile(orb.mod_dir .. "/process.lua")
-- pp = dofile(orb.mod_dir .. "/PrettyPrint.lua")

-- for interactive use, but also as a sample of how the API works:
if(arg) then
   -- start with an empty filesystem
   f_raw = orb.fs.new_raw()
   f0 = orb.fs.seed(orb.fs.proxy(f_raw, "root", f_raw),
                    {"technomancy", "buddyberg", "zacherson"})
   f1 = orb.fs.proxy(f_raw, "technomancy", f_raw)
   e0 = orb.shell.new_env("root")
   e1 = orb.shell.new_env("technomancy")

   co = orb.process.spawn(f1, e1, "smash") -- Open an interactive shell
   -- till we have non-blocking io.read, the scheduler isn't going to do jack
   -- when run from regular stdin
   while coroutine.status(co) ~= "dead" do orb.process.scheduler(f0) end

   -- tests
   t_groups = orb.shell.groups(f0, "technomancy")
   assert(orb.utils.includes(t_groups, "technomancy"))
   assert(orb.utils.includes(t_groups, "all"))
   assert(not orb.utils.includes(t_groups, "zacherson"))

   orb.shell.exec(f1, e1, "mkdir mydir")
   orb.shell.exec(f1, e1, "mkdir /tmp/hi")
   orb.shell.exec(f1, e1, "ls /tmp/hi")
   orb.shell.exec(f1, e1, "ls > /tmp/mydir")
   orb.shell.exec(f1, e0, "ls /etc > /tmp/ls-etc")
   orb.shell.exec(f1, e1, "cat /bin/cat > /tmp/cat")

   assert(orb.fs.readable(f0, f1["/home/technomancy"], "technomancy"))
   assert(orb.fs.readable(f0, f1["/bin"], "technomancy"))
   assert(orb.fs.readable(f0, f1["/bin"], "zacherson"))
   assert(orb.fs.writeable(f0, f1["/home/technomancy"], "technomancy"))
   assert(orb.fs.writeable(f0, f1["/tmp"], "technomancy"))

   -- assert(not orb.fs.writeable(f0, f1["/etc"], "technomancy"))
   -- assert(not orb.fs.writeable(f0, f1["/home/zacherson"], "technomancy"))
   -- assert(not orb.fs.readable(f0, f1["/home/zacherson"], "technomancy"))
end

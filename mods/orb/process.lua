orb.process = {
   spawn = function(f, env, command)
      local co = coroutine.create(function()
            orb.shell.exec(f, env, "smash") end)
      local id = orb.process.id_for(co)
      f.proc[env.USER][id] = { thread = co,
                               command = command,
                               id = id,
                               _user = env.USER,
      }
      return co, id
   end,

   id_for = function(p)
      return tostring(p):match(": 0x(.+)")
   end,

   scheduler = function(f)
      for u,procs in pairs(f.proc) do
         if(type(procs) == "table") then
            for k,p in pairs(procs) do
               if(type(p) == "table" and p.thread) then
                  if(coroutine.status(p.thread) == "dead") then
                     procs[k] = nil
                  else
                     coroutine.resume(p.thread)
                  end
               end
            end
         end
      end
   end,
}

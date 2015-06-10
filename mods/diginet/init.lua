local required_fields = {"destination", "source", "method"}

local normalize_address = function(address)
   if(type(address) == "table") then
      return address
   elseif(type(address) == "string") then
      return minetest.string_to_pos(address)
   else
      error("Unknown address type: " .. type(address))
   end
end

local normalize = function(packet)
   for _,f in pairs(required_fields) do
      assert(packet[f], "Missing required field " .. f) end
   packet.source = normalize_address(packet.source)
   packet.destination = normalize_address(packet.destination)
   return packet
end

local getspec = function(node)
   return minetest.registered_nodes[node.name] and
      minetest.registered_nodes[node.name].diginet
end

local reply_to = function(original, new)
      new.source = original.destination
      new.destination = original.source
      if(original.player) then new.player = original.player end
      if(original.request_id) then new.in_reply_to = original.request_id end
      return new
end

local reply_err = function(original, spec, message)
   if(not spec.error) then return end
   spec.error(original.source, reply_to(packet, {err = message}))
end

local nodes_for = function(address)
   local dest_node = minetest.get_node(address)
   return {dest_node} -- TODO: multicast
end

diginet = {
   -- Send a packet over diginet. Required fields: source, destination, method.
   send = function(packet)
      normalize(packet)
      print("Sending " .. minetest.serialize(packet))
      for _,dest_node in pairs(nodes_for(packet.destination)) do
         local spec = getspec(dest_node)
         if(dest_node and spec) then
            local handler = spec[packet.method]
            if(handler) then
               handler(packet.destination, packet)
            else
               reply_err(packet, spec, "No method " .. packet.method)
            end
         else
            reply_err(packet, spec, "Undeliverable to " ..
                         minetest.pos_to_string(packet.destination))
         end
      end
   end,

   -- Send a packet in response to an original packet. Packet sent will have
   -- source, destination, and player/in_reply_to (if applicable) calculated
   -- from original packet.
   reply = function(original, reply_packet)
      diginet.send(reply_to(original, reply_packet))
   end,

   -- Return a function that will send a specified packet with a few fields
   -- overridden which are accepted as args to that function.
   partial = function(packet, fields)
      local packet_str = minetest.serialize(packet)
      return function(...)
         local values = {...}
         local p2 = minetest.deserialize(packet_str)
         for i,f in ipairs(fields) do
            p2[f] = values[i]
         end
         diginet.send(p2)
      end
   end
}

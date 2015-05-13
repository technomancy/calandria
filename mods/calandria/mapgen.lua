-- Mapgeneration
--

minetest.register_on_generated(function(minp, maxp, blockseed)

    -- Generates first node at (0,0,0)
    if (minp.x <= 0 and maxp.x >= 0) and
       (minp.y <= 0 and maxp.y >= 0) and
       (minp.z <= 0 and maxp.z >= 0) then
           minetest.set_node({x=0,y=0,z=0},{name="calandria:light"})
    end

end)

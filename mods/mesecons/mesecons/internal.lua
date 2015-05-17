-- Internal.lua - The core of mesecons
--
-- For more practical developer resources see http://mesecons.net/developers.php
--
-- Function overview
-- mesecon.get_effector(nodename)	--> Returns the mesecons.effector -specifictation in the nodedef by the nodename
-- mesecon.get_receptor(nodename)	--> Returns the mesecons.receptor -specifictation in the nodedef by the nodename
-- mesecon.get_conductor(nodename)	--> Returns the mesecons.conductor-specifictation in the nodedef by the nodename
-- mesecon.get_any_inputrules (node)	--> Returns the rules of a node if it is a conductor or an effector
-- mesecon.get_any_outputrules (node)	--> Returns the rules of a node if it is a conductor or a receptor

-- RECEPTORS
-- mesecon.is_receptor(nodename)	--> Returns true if nodename is a receptor
-- mesecon.is_receptor_on(nodename	--> Returns true if nodename is an receptor with state = mesecon.state.on
-- mesecon.is_receptor_off(nodename)	--> Returns true if nodename is an receptor with state = mesecon.state.off
-- mesecon.receptor_get_rules(node)	--> Returns the rules of the receptor (mesecon.rules.default if none specified)

-- EFFECTORS
-- mesecon.is_effector(nodename)	--> Returns true if nodename is an effector
-- mesecon.is_effector_on(nodename)	--> Returns true if nodename is an effector with nodedef.mesecons.effector.action_off
-- mesecon.is_effector_off(nodename)	--> Returns true if nodename is an effector with nodedef.mesecons.effector.action_on
-- mesecon.effector_get_rules(node)	--> Returns the input rules of the effector (mesecon.rules.default if none specified)

-- SIGNALS
-- mesecon.activate(pos, node, depth)				--> Activates   the effector node at the specific pos (calls nodedef.mesecons.effector.action_on), higher depths are executed later
-- mesecon.deactivate(pos, node, depth)				--> Deactivates the effector node at the specific pos (calls nodedef.mesecons.effector.action_off), higher depths are executed later
-- mesecon.changesignal(pos, node, rulename, newstate, depth)	--> Changes     the effector node at the specific pos (calls nodedef.mesecons.effector.action_change), higher depths are executed later

-- CONDUCTORS
-- mesecon.is_conductor(nodename)	--> Returns true if nodename is a conductor
-- mesecon.is_conductor_on(node		--> Returns true if node is a conductor with state = mesecon.state.on
-- mesecon.is_conductor_off(node)	--> Returns true if node is a conductor with state = mesecon.state.off
-- mesecon.get_conductor_on(node_off)	--> Returns the onstate  nodename of the conductor
-- mesecon.get_conductor_off(node_on)	--> Returns the offstate nodename of the conductor
-- mesecon.conductor_get_rules(node)	--> Returns the input+output rules of a conductor (mesecon.rules.default if none specified)

-- HIGH-LEVEL Internals
-- mesecon.is_power_on(pos)				--> Returns true if pos emits power in any way
-- mesecon.is_power_off(pos)				--> Returns true if pos does not emit power in any way
-- mesecon.turnon(pos, link) 				--> link is the input rule that caused calling turnon, turns on every connected node, iterative
-- mesecon.turnoff(pos, link)				--> link is the input rule that caused calling turnoff, turns off every connected node, iterative
-- mesecon.connected_to_receptor(pos, link)		--> Returns true if pos is connected to a receptor directly or via conductors, iterative
-- mesecon.rules_link(output, input, dug_outputrules)	--> Returns true if outputposition + outputrules = inputposition and inputposition + inputrules = outputposition (if the two positions connect)
-- mesecon.rules_link_anydir(outp., inp., d_outpr.)	--> Same as rules mesecon.rules_link but also returns true if output and input are swapped
-- mesecon.is_powered(pos)				--> Returns true if pos is powered by a receptor or a conductor

-- RULES ROTATION helpers
-- mesecon.rotate_rules_right(rules)
-- mesecon.rotate_rules_left(rules)
-- mesecon.rotate_rules_up(rules)
-- mesecon.rotate_rules_down(rules)
-- These functions return rules that have been rotated in the specific direction

-- General
function mesecon.get_effector(nodename)
	if  minetest.registered_nodes[nodename]
	and minetest.registered_nodes[nodename].mesecons
	and minetest.registered_nodes[nodename].mesecons.effector then
		return minetest.registered_nodes[nodename].mesecons.effector
	end
end

function mesecon.get_receptor(nodename)
	if  minetest.registered_nodes[nodename]
	and minetest.registered_nodes[nodename].mesecons
	and minetest.registered_nodes[nodename].mesecons.receptor then
		return minetest.registered_nodes[nodename].mesecons.receptor
	end
end

function mesecon.get_conductor(nodename)
	if  minetest.registered_nodes[nodename]
	and minetest.registered_nodes[nodename].mesecons
	and minetest.registered_nodes[nodename].mesecons.conductor then
		return minetest.registered_nodes[nodename].mesecons.conductor
	end
end

function mesecon.get_any_outputrules (node)
	if mesecon.is_conductor(node.name) then
		return mesecon.conductor_get_rules(node)
	elseif mesecon.is_receptor(node.name) then
		return mesecon.receptor_get_rules(node)
	end
end

function mesecon.get_any_inputrules (node)
	if mesecon.is_conductor(node.name) then
		return mesecon.conductor_get_rules(node)
	elseif mesecon.is_effector(node.name) then
		return mesecon.effector_get_rules(node)
	end
end

function mesecon.get_any_rules (node)
	return mesecon.mergetable(mesecon.get_any_inputrules(node) or {},
		mesecon.get_any_outputrules(node) or {})
end

-- Receptors
-- Nodes that can power mesecons
function mesecon.is_receptor_on(nodename)
	local receptor = mesecon.get_receptor(nodename)
	if receptor and receptor.state == mesecon.state.on then
		return true
	end
	return false
end

function mesecon.is_receptor_off(nodename)
	local receptor = mesecon.get_receptor(nodename)
	if receptor and receptor.state == mesecon.state.off then
		return true
	end
	return false
end

function mesecon.is_receptor(nodename)
	local receptor = mesecon.get_receptor(nodename)
	if receptor then
		return true
	end
	return false
end

function mesecon.receptor_get_rules(node)
	local receptor = mesecon.get_receptor(node.name)
	if receptor then
		local rules = receptor.rules
		if type(rules) == 'function' then
			return rules(node)
		elseif rules then
			return rules
		end
	end

	return mesecon.rules.default
end

-- Effectors
-- Nodes that can be powered by mesecons
function mesecon.is_effector_on(nodename)
	local effector = mesecon.get_effector(nodename)
	if effector and effector.action_off then
		return true
	end
	return false
end

function mesecon.is_effector_off(nodename)
	local effector = mesecon.get_effector(nodename)
	if effector and effector.action_on then
		return true
	end
	return false
end

function mesecon.is_effector(nodename)
	local effector = mesecon.get_effector(nodename)
	if effector then
		return true
	end
	return false
end

function mesecon.effector_get_rules(node)
	local effector = mesecon.get_effector(node.name)
	if effector then
		local rules = effector.rules
		if type(rules) == 'function' then
			return rules(node)
		elseif rules then
			return rules
		end
	end
	return mesecon.rules.default
end

-- #######################
-- # Signals (effectors) #
-- #######################

-- Activation:
mesecon.queue:add_function("activate", function (pos, rulename)
	local node = minetest.get_node(pos)
	local effector = mesecon.get_effector(node.name)

	if effector and effector.action_on then
		effector.action_on(pos, node, rulename)
	end
end)

function mesecon.activate(pos, node, rulename, depth)
	if rulename == nil then
		for _,rule in ipairs(mesecon.effector_get_rules(node)) do
			mesecon.activate(pos, node, rule, depth + 1)
		end
		return
	end
	mesecon.queue:add_action(pos, "activate", {rulename}, nil, rulename, 1 / depth)
end


-- Deactivation
mesecon.queue:add_function("deactivate", function (pos, rulename)
	local node = minetest.get_node(pos)
	local effector = mesecon.get_effector(node.name)

	if effector and effector.action_off then
		effector.action_off(pos, node, rulename)
	end
end)

function mesecon.deactivate(pos, node, rulename, depth)
	if rulename == nil then
		for _,rule in ipairs(mesecon.effector_get_rules(node)) do
			mesecon.deactivate(pos, node, rule, depth + 1)
		end
		return
	end
	mesecon.queue:add_action(pos, "deactivate", {rulename}, nil, rulename, 1 / depth)
end


-- Change
mesecon.queue:add_function("change", function (pos, rulename, changetype)
	local node = minetest.get_node(pos)
	local effector = mesecon.get_effector(node.name)

	if effector and effector.action_change then
		effector.action_change(pos, node, rulename, changetype)
	end
end)

function mesecon.changesignal(pos, node, rulename, newstate, depth)
	if rulename == nil then
		for _,rule in ipairs(mesecon.effector_get_rules(node)) do
			mesecon.changesignal(pos, node, rule, newstate, depth + 1)
		end
		return
	end

	-- Include "change" in overwritecheck so that it cannot be overwritten
	-- by "active" / "deactivate" that will be called upon the node at the same time.
	local overwritecheck = {"change", rulename}
	mesecon.queue:add_action(pos, "change", {rulename, newstate}, nil, overwritecheck, 1 / depth)
end

-- Conductors

function mesecon.is_conductor_on(node, rulename)
	local conductor = mesecon.get_conductor(node.name)
	if conductor then
		if conductor.state then
			return conductor.state == mesecon.state.on
		end
		if conductor.states then
			if not rulename then
				return mesecon.getstate(node.name, conductor.states) ~= 1
			end
			local bit = mesecon.rule2bit(rulename, mesecon.conductor_get_rules(node))
			local binstate = mesecon.getbinstate(node.name, conductor.states)
			return mesecon.get_bit(binstate, bit)
		end
	end
	return false
end

function mesecon.is_conductor_off(node, rulename)
	local conductor = mesecon.get_conductor(node.name)
	if conductor then
		if conductor.state then
			return conductor.state == mesecon.state.off
		end
		if conductor.states then
			if not rulename then
				return mesecon.getstate(node.name, conductor.states) == 1
			end
			local bit = mesecon.rule2bit(rulename, mesecon.conductor_get_rules(node))
			local binstate = mesecon.getbinstate(node.name, conductor.states)
			return not mesecon.get_bit(binstate, bit)
		end
	end
	return false
end

function mesecon.is_conductor(nodename)
	local conductor = mesecon.get_conductor(nodename)
	if conductor then
		return true
	end
	return false
end

function mesecon.get_conductor_on(node_off, rulename)
	local conductor = mesecon.get_conductor(node_off.name)
	if conductor then
		if conductor.onstate then
			return conductor.onstate
		end
		if conductor.states then
			local bit = mesecon.rule2bit(rulename, mesecon.conductor_get_rules(node_off))
			local binstate = mesecon.getbinstate(node_off.name, conductor.states)
			binstate = mesecon.set_bit(binstate, bit, "1")
			return conductor.states[tonumber(binstate,2)+1]
		end
	end
	return offstate
end

function mesecon.get_conductor_off(node_on, rulename)
	local conductor = mesecon.get_conductor(node_on.name)
	if conductor then
		if conductor.offstate then
			return conductor.offstate
		end
		if conductor.states then
			local bit = mesecon.rule2bit(rulename, mesecon.conductor_get_rules(node_on))
			local binstate = mesecon.getbinstate(node_on.name, conductor.states)
			binstate = mesecon.set_bit(binstate, bit, "0")
			return conductor.states[tonumber(binstate,2)+1]
		end
	end
	return onstate
end

function mesecon.conductor_get_rules(node)
	local conductor = mesecon.get_conductor(node.name)
	if conductor then
		local rules = conductor.rules
		if type(rules) == 'function' then
			return rules(node)
		elseif rules then
			return rules
		end
	end
	return mesecon.rules.default
end

-- some more general high-level stuff

function mesecon.is_power_on(pos, rulename)
	local node = minetest.get_node(pos)
	if mesecon.is_conductor_on(node, rulename) or mesecon.is_receptor_on(node.name) then
		return true
	end
	return false
end

function mesecon.is_power_off(pos, rulename)
	local node = minetest.get_node(pos)
	if mesecon.is_conductor_off(node, rulename) or mesecon.is_receptor_off(node.name) then
		return true
	end
	return false
end

function mesecon.turnon(pos, link)
	local frontiers = {{pos = pos, link = link}}

	local depth = 1
	while frontiers[depth] do
		local f = frontiers[depth]
		local node = minetest.get_node_or_nil(f.pos)

		-- area not loaded, postpone action
		if not node then
			mesecon.queue:add_action(f.pos, "turnon", {link}, nil, true)
		elseif mesecon.is_conductor_off(node, f.link) then
			local rules = mesecon.conductor_get_rules(node)

			minetest.swap_node(f.pos, {name = mesecon.get_conductor_on(node, f.link),
				param2 = node.param2})

			-- call turnon on neighbors: normal rules
			for _, r in ipairs(mesecon.rule2meta(f.link, rules)) do
				local np = mesecon.addPosRule(f.pos, r)

				-- area not loaded, postpone action
				if not minetest.get_node_or_nil(np) then
					mesecon.queue:add_action(np, "turnon", {rulename},
						nil, true)
				else
					local links = mesecon.rules_link_rule_all(f.pos, r)
					for _, l in ipairs(links) do
						table.insert(frontiers, {pos = np, link = l})
					end
				end
			end
		elseif mesecon.is_effector(node.name) then
			mesecon.changesignal(f.pos, node, f.link, mesecon.state.on, depth)
			if mesecon.is_effector_off(node.name) then
				mesecon.activate(f.pos, node, f.link, depth)
			end
		end
		depth = depth + 1
	end
end

mesecon.queue:add_function("turnon", function (pos, rulename, recdepth)
	mesecon.turnon(pos, rulename, recdepth)
end)

function mesecon.turnoff(pos, link)
	local frontiers = {{pos = pos, link = link}}

	local depth = 1
	while frontiers[depth] do
		local f = frontiers[depth]
		local node = minetest.get_node_or_nil(f.pos)

		-- area not loaded, postpone action
		if not node then
			mesecon.queue:add_action(f.pos, "turnoff", {link}, nil, true)
		elseif mesecon.is_conductor_on(node, f.link) then
			local rules = mesecon.conductor_get_rules(node)

			minetest.swap_node(f.pos, {name = mesecon.get_conductor_off(node, f.link),
				param2 = node.param2})

			-- call turnoff on neighbors: normal rules
			for _, r in ipairs(mesecon.rule2meta(f.link, rules)) do
				local np = mesecon.addPosRule(f.pos, r)

				-- area not loaded, postpone action
				if not minetest.get_node_or_nil(np) then
					mesecon.queue:add_action(np, "turnoff", {rulename},
						nil, true)
				else
					local links = mesecon.rules_link_rule_all(f.pos, r)
					for _, l in ipairs(links) do
						table.insert(frontiers, {pos = np, link = l})
					end
				end
			end
		elseif mesecon.is_effector(node.name) then
			mesecon.changesignal(f.pos, node, f.link, mesecon.state.off, depth)
			if mesecon.is_effector_on(node.name) and not mesecon.is_powered(f.pos) then
				mesecon.deactivate(f.pos, node, f.link, depth)
			end
		end
		depth = depth + 1
	end
end

mesecon.queue:add_function("turnoff", function (pos, rulename, recdepth)
	mesecon.turnoff(pos, rulename, recdepth)
end)


function mesecon.connected_to_receptor(pos, link)
	local node = minetest.get_node(pos)

	-- Check if conductors around are connected
	local rules = mesecon.get_any_inputrules(node)
	if not rules then return false end

	for _, rule in ipairs(mesecon.rule2meta(link, rules)) do
		local links = mesecon.rules_link_rule_all_inverted(pos, rule)
		for _, l in ipairs(links) do
			local np = mesecon.addPosRule(pos, l)
			if mesecon.find_receptor_on(np, mesecon.invertRule(l)) then
				return true
			end
		end
	end

	return false
end

function mesecon.find_receptor_on(pos, link)
	local frontiers = {{pos = pos, link = link}}
	local checked = {}

	-- List of positions that have been searched for onstate receptors
	local depth = 1
	while frontiers[depth] do
		local f = frontiers[depth]
		local node = minetest.get_node_or_nil(f.pos)

		if not node then return false end
		if mesecon.is_receptor_on(node.name) then return true end
		if mesecon.is_conductor_on(node, f.link) then
			local rules = mesecon.conductor_get_rules(node)

			-- call turnoff on neighbors: normal rules
			for _, r in ipairs(mesecon.rule2meta(f.link, rules)) do
				local np = mesecon.addPosRule(f.pos, r)

				local links = mesecon.rules_link_rule_all_inverted(f.pos, r)
				for _, l in ipairs(links) do
					local checkedstring = np.x..np.y..np.z..l.x..l.y..l.z
					if not checked[checkedstring] then
						table.insert(frontiers, {pos = np, link = l})
						checked[checkedstring] = true
					end
				end
			end
			
		end
		depth = depth + 1
	end
end

function mesecon.rules_link(output, input, dug_outputrules) --output/input are positions (outputrules optional, used if node has been dug), second return value: the name of the affected input rule
	local outputnode = minetest.get_node(output)
	local inputnode = minetest.get_node(input)
	local outputrules = dug_outputrules or mesecon.get_any_outputrules (outputnode)
	local inputrules = mesecon.get_any_inputrules (inputnode)
	if not outputrules or not inputrules then
		return
	end

	for _, outputrule in ipairs(mesecon.flattenrules(outputrules)) do
		-- Check if output sends to input
		if mesecon.cmpPos(mesecon.addPosRule(output, outputrule), input) then
			for _, inputrule in ipairs(mesecon.flattenrules(inputrules)) do
				-- Check if input accepts from output
				if  mesecon.cmpPos(mesecon.addPosRule(input, inputrule), output) then
					return true, inputrule
				end
			end
		end
	end
	return false
end

function mesecon.rules_link_rule_all(output, rule)
	local input = mesecon.addPosRule(output, rule)
	local inputnode = minetest.get_node(input)
	local inputrules = mesecon.get_any_inputrules (inputnode)
	if not inputrules then
		return {}
	end
	local rules = {}
	
	for _, inputrule in ipairs(mesecon.flattenrules(inputrules)) do
		-- Check if input accepts from output
		if  mesecon.cmpPos(mesecon.addPosRule(input, inputrule), output) then
			table.insert(rules, inputrule)
		end
	end
	return rules
end

function mesecon.rules_link_rule_all_inverted(input, rule)
	--local irule = mesecon.invertRule(rule)
	local output = mesecon.addPosRule(input, rule)
	local outputnode = minetest.get_node(output)
	local outputrules = mesecon.get_any_outputrules (outputnode)
	if not outputrules then
		return {}
	end
	local rules = {}
	
	for _, outputrule in ipairs(mesecon.flattenrules(outputrules)) do
		if  mesecon.cmpPos(mesecon.addPosRule(output, outputrule), input) then
			table.insert(rules, mesecon.invertRule(outputrule))
		end
	end
	return rules
end

function mesecon.rules_link_anydir(pos1, pos2)
	return mesecon.rules_link(pos1, pos2) or mesecon.rules_link(pos2, pos1)
end

function mesecon.is_powered(pos, rule)
	local node = minetest.get_node(pos)
	local rules = mesecon.get_any_inputrules(node)
	if not rules then return false end

	-- List of nodes that send out power to pos
	local sourcepos = {}

	if not rule then
		for _, rule in ipairs(mesecon.flattenrules(rules)) do
			local rulenames = mesecon.rules_link_rule_all_inverted(pos, rule)
			for _, rname in ipairs(rulenames) do
				local np = mesecon.addPosRule(pos, rname)
				local nn = minetest.get_node(np)
				if (mesecon.is_conductor_on (nn, mesecon.invertRule(rname))
				or mesecon.is_receptor_on (nn.name)) then
					table.insert(sourcepos, np)
				end
			end
		end
	else
		local rulenames = mesecon.rules_link_rule_all_inverted(pos, rule)
		for _, rname in ipairs(rulenames) do
			local np = mesecon.addPosRule(pos, rname)
			local nn = minetest.get_node(np)
			if (mesecon.is_conductor_on (nn, mesecon.invertRule(rname))
			or mesecon.is_receptor_on (nn.name)) then
				table.insert(sourcepos, np)
			end
		end
	end

	-- Return FALSE if not powered, return list of sources if is powered
	if (#sourcepos == 0) then return false
	else return sourcepos end
end

--Rules rotation Functions:
function mesecon.rotate_rules_right(rules)
	local nr = {}
	for i, rule in ipairs(rules) do
		table.insert(nr, {
			x = -rule.z, 
			y =  rule.y, 
			z =  rule.x,
			name = rule.name})
	end
	return nr
end

function mesecon.rotate_rules_left(rules)
	local nr = {}
	for i, rule in ipairs(rules) do
		table.insert(nr, {
			x =  rule.z, 
			y =  rule.y, 
			z = -rule.x,
			name = rule.name})
	end
	return nr
end

function mesecon.rotate_rules_down(rules)
	local nr = {}
	for i, rule in ipairs(rules) do
		table.insert(nr, {
			x = -rule.y, 
			y =  rule.x, 
			z =  rule.z,
			name = rule.name})
	end
	return nr
end

function mesecon.rotate_rules_up(rules)
	local nr = {}
	for i, rule in ipairs(rules) do
		table.insert(nr, {
			x =  rule.y, 
			y = -rule.x, 
			z =  rule.z,
			name = rule.name})
	end
	return nr
end

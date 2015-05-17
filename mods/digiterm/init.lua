
--a function for producing a digiterm form with specified output and input
local function digiterm_formspec(output, input)
	return 'size[10,11] textarea[.25,.25;10,10.5;output;;'..output..'] button[0,9.5;10,1;update;update] field[.25,10.75;9,1;input;;'..input..'] button[9,10.5;1,1;submit;submit]'
end

--extremely hacky
--but neccessary since there doesn't seem to be any better way to refresh a formspec
local function hacky_quote_new_digiterm_formspec(startspace)
	return (startspace and ' ' or '')..digiterm_formspec('${output}', '${input}');
end

--a basic digiterm!
minetest.register_node('digiterm:digiterm', {
	description = 'digiterm',
	
	--set graphics
	tiles = {'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_front.png'},
	paramtype2 = 'facedir',
	
	--it's kind of stone-like
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
	
	--digiline stuff (mostly based on other digiline things as suggested)
	digiline = {
		receptor = {},
		effector = {
			action = function(pos, node, channel, msg)
				local meta = minetest.get_meta(pos);
				
				--ignore anything that isn't our channel
				if channel ~= meta:get_string('channel') then return end
				
				--if it's a string, append to the end of our output string
				if type(msg) == 'string' then meta:set_string('output', meta:get_string('output')..msg);
				
				--it may also be a control code; check if it's a table with a 'code' member
				elseif type(msg) == 'table' and msg.code then
					
					--the code 'cls' clears out the output
					if msg.code == 'cls' then meta:set_string('output', ''); end
				end
			end
		},
	},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos);
		
		--initialize the input and output buffers
		meta:set_string('output', '');
		meta:set_string('input', '');
		
		--set an initial formspec for specifying the channel
		meta:set_string('formspec', 'field[channel;channel;${channel}]');
		
		--start on an empty channel
		meta:set_string('channel', '');
	end,
	
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos);
		
		--are we to set the channel?
		if fields.channel then
			
			--if so, set it
			meta:set_string('channel', fields.channel);
			
			--replace with the operating formspec
			meta:set_string('formspec', hacky_quote_new_digiterm_formspec(false));
			
			--and disregard the rest of this callback
			return;
			
		end
		
		--has the user touched the submit button?
		if fields.submit then
			
			--if so, submit and reset the input field
			digiline:receptor_send(pos, digiline.rules.default, meta:get_string('channel'), fields.input);
			meta:set_string('input', '');
		else
			
			--otherwise, update the input so that it doesn't change
			meta:set_string('input', fields.input);
		end
		
		--refresh the formspec hackishly
		meta:set_string('formspec', hacky_quote_new_digiterm_formspec(meta:get_string('formspec'):sub(0, 1) ~= ' '));
	end,
});

--add a craft recipe for digiterms
minetest.register_craft({
	output = 'digiterm:digiterm',
	recipe = {
		{'default:glass', 'default:glass', 'default:glass'},
		{'digilines:wire_std_00000000', 'mesecons_luacontroller:luacontroller0000', 'digilines:wire_std_00000000'},
		{'default:stone', 'default:steel_ingot', 'default:stone'},
	},
});

--creation and usage of node positions encoded into formspec names
local function make_secure_digiterm_formspec_name(pos)
	return 'digitermspec{x='..tostring(pos.x)..',y='..tostring(pos.y)..',z='..tostring(pos.z)..'}';
end
local function retrieve_secure_digiterm_pos(formname)
	
	--try to pull the vector out of the form name
	local possstr;
	posstr = formname:match('^digitermspec({x=%-?%d*%.?%d*,y=%-?%d*%.?%d*,z=%-?%d*%.?%d*})$');
	
	--if we didn't get one, give up
	if not posstr then return; end
	
	--otherwise, grab the position
	return loadstring('return '..posstr)();
end

--a secure digiterm!
minetest.register_node('digiterm:digiterm_secure', {
	description = 'secure digiterm',
	
	--set graphics
	tiles = {'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_secure_front.png'},
	paramtype2 = 'facedir',
	
	--it's kind of stone-like
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
	
	--digiline stuff (mostly based on other digiline things as suggested)
	digiline = {
		receptor = {},
		effector = {
			action = function(pos, node, channel, msg)
				local meta = minetest.get_meta(pos);
				
				--ignore anything that isn't our channel
				if channel ~= meta:get_string('channel') then return end
				
				--try to find some id
				local player;
				if type(msg) == 'table' and msg.player then
					
					--attempt to grab the player name if it's a string
					player = msg.player == 'string' and msg.player;
					
					--if the id is passed correctly and the field msg exists, than that's the actual msg
					msg = msg.msg or msg;
				end
				
				--otherwise, assume the last encountered player is the target of the message
				if not player then player = meta:get_string('last_player'); end
				
				--if there is no such player, give up
				if not player then return; end
				
				--if the player in question doesn't have a session here, give up
				if not meta:get_int(player..'_seq') then return; end
				
				--for strings, append at the end of the player's output
				if type(msg) == 'string' then meta:set_string(player..'_output', meta:get_string(player..'_output')..msg);
				
				--handle control codes too
				elseif type(msg) == 'table' and msg.code then
					
					--the code 'cls' clears out the output
					if msg.code == 'cls' then meta:set_string(player..'_output', ''); end
				end
			end
		},
	},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos);
		
		--set an initial formspec for specifying the channel
		meta:set_string('formspec', 'field[channel;channel;${channel}]');
		
		--start on an empty channel
		meta:set_string('channel', '');
	end,
	
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos);
		
		--are we to set the channel?
		if fields.channel then
			
			--if so, set it
			meta:set_string('channel', fields.channel);
			
			--and dump the formspec
			meta:set_string('formspec', '');
		end
	end,
	
	on_rightclick = function(pos, node, player, itemstack)
		local meta = minetest.get_meta(pos);
		
		--grab the player's name
		local name = player:get_player_name();
		
		--log this person as the last visitor
		meta:set_string('last_player', name);
		
		--grab the input, output, and current message sequence number for this player
		local output, input, seq = meta:get_string(name..'_output'), meta:get_string(name..'_input'), meta:get_int(name..'_seq');
		
		--if any are nil, re-initialize all
		if not output or not input or not seq then
			output, input, seq = '', '', 0;
			meta:set_string(name..'_output', output);
			meta:set_string(name..'_input', input);
			meta:set_int(name..'_seq', seq);
		end
		
		--send a message to let the network so that it can send a greeting
		digiline:receptor_send(pos, digiline.rules.default, meta:get_string('channel'), function() return {player=name, seq=seq, code='init'} end);
		
		--bump the sequence number
		meta:set_int(name..'_seq', seq + 1);
		
		--show them the formspec
		minetest.show_formspec(name, make_secure_digiterm_formspec_name(pos), digiterm_formspec(output, input));
		
		--we don't need to do anything with itemstack
		return itemstack;
	end,
});

--we need to register something to pick up our formspec submissions
minetest.register_on_player_receive_fields(function (player, formname, fields)
	
	--we shall attempt to obtain the node coordinates from the formname
	local pos = retrieve_secure_digiterm_pos(formname);
	
	--if that failed, then we pass execution on
	if not pos then return false; end
	
	--otherwise, grab some metadata and the player name
	local meta = minetest.get_meta(pos);
	local name = player:get_player_name();
	
	--has the user touched the submit button?
	if fields.submit then
		
		--if so, submit and reset the input field
		local seq = meta:get_int(name..'_seq');
		digiline:receptor_send(pos, digiline.rules.default, meta:get_string('channel'), function() return {player=name, seq=seq, msg=fields.input} end);
		meta:set_string(name..'_input', '');
		
		--and bump the sequence number
		meta:set_int(name..'_seq', seq + 1);
	else
		
		--otherwise, update the input so that it doesn't change
		meta:set_string(name..'_input', fields.input);
	end
	
	--re-show the formspec
	minetest.show_formspec(name, make_secure_digiterm_formspec_name(pos), digiterm_formspec(meta:get_string(name..'_output'), meta:get_string(name..'_input')));
	
end);

--add a craft recipe for the secure variant
minetest.register_craft({
	output = 'digiterm:digiterm_secure',
	recipe = {
		{'', 'default:steel_ingot', ''},
		{'default:steel_ingot', 'digiterm:digiterm', 'default:steel_ingot'},
		{'', 'default:steel_ingot', ''},
	},
});

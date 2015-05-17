This is digiterm: a [Minetest](http://minetest.net/) mod that provides a couple terminal nodes for providing user interface in [Digilines](https://forum.minetest.net/viewtopic.php?id=5263) networks.

The first of two nodes that this mod provides is a regular digiterm. To use it, simply place it down and right-click it to set the channel that it will operate on. After setup, you'll see two boxes and two buttons. Any messages on the digiline network sent on the channel that this digiterm is set to will show up in the large box, and messages can be sent out to the digiline network by typing them in to the bottom box and pressing the 'submit' button. The 'update' button is necessary because there is no way of automatically updating formspecs without clobbering any in-progress input; pressing it will submit the form and then re-display with updated output and the current (now saved) input. Normal digiterms send and receive their messages as simple strings, do not append newlines automatically on either end of transmission, and store their state on a per-node basis. One can also issue control codes as a table containing a 'code' key; the only one supported thus far is `{code='cls'}` which clears the output area.

As an example, a simple chat machine can be constructed using two digiterms set to the channels `term1` and `term2` and one luacontroller with the following code:

```lua
if event.type == 'digiline' then
	if event.channel == 'term1' then digiline_send('term2', event.msg..'\n');
	elseif event.channel == 'term2' then digiline_send('term1', event.msg..'\n');
	end
end
```

The second node defined by this mod is the secure digiterm. Secure digiterms appear almost exactly the same as their "unsecure" counterparts, but their inner workings are almost entirely different. Secure digiterms manage each user's session on a given node separately, so leftover information from one user will not be visible to another user that logs on after them, and two people can use one secure digiterm simultaneously. Instead of sending messages as plain strings, secure digiterms submit user information in the form of a function that returns a table such as `{player="", seq=0, msg=""}`, where 'player' is a string containing the name of the player sending the message, 'msg' is a string containing the actual message, and 'seq' is a unique integer that is incremented with each message. Secure digiterms will also notify the digiline network when a player starts a session by sending a message in the form of a function returning something like `{player="", seq=0, code='init'}` where 'player' and 'seq' have the same meanings as above and 'code' is always 'init' (to catch responses to this, one will have to press 'update' after opening the terminal). Secure digiterms also take their input in the form of plain strings (in which case messages are routed to the last seen player's session), but, if you want to make sure that you're message gets across, you can send it as a table of the form `{player="", msg=""}`, where 'player' is the name of the intended recipient and 'msg' is the message you wish to send them. Secure digiterms also take control codes; these are tables that look like `{player="", code=""}`, where 'player' is the name of recipient and 'code' is one of the same control codes used by regular digiterms (still only 'cls' at the moment).

What makes secure digiterms secure is their leverage of the fact that luacontrollers cannot define functions. A server receiving messages from a secure digiterm can know that they're authentic because they cannot be forged by an imposter luacontroller (as they cannot define functions) and that they haven't been tampered with since functions are opaque and immutable. Would-be cyber-griefers can store function messages sent across the network and redeploy them later (to a certain extent; functions are impossible to serialize), but they can't increment the 'seq' member, thus well-written servers will be able to easily filter out the re-used messages.

As a demonstration of secure digiterms, if the following code is loaded onto a luacontroller connected to a secure digiterm set to the 'term' channel, it will show users a welcome message and then echo everything that they enter back to them, with their name and sequence number:

```lua
if event.type == 'digiline' and event.channel == 'term' then
	local msg = event.msg();
	local seq = mem[msg.player..'_seq'];
	if seq and seq >= msg.seq then return end
	mem[msg.player..'_seq'] = msg.seq;
	if msg.code == 'init' then
		digiline_send('term', {player=msg.player, code='cls'});
		digiline_send('term', {player=msg.player, msg='Hello, '..msg.player..'; welcome to the digiterm demonstration!\n'});
	else
		digiline_send('term', {player=msg.player, msg='<'..msg.player..'('..tostring(msg.seq)..')> '..msg.msg..'\n'});
	end
end
```

This mod is released under the same licensing as the digilines mod (LGPL/WTFPL).

# Calandria

This is a mod for games that run on the
[Minetest engine](http://www.minetest.net) such as
[Carbone](https://github.com/calinou/carbone/) and
[Moontest](https://github.com/Amaz1/moontest).
It is designed to encourage exploration of programming and other
technical skills by adding programmable unixlike servers.

Do not use this mod on public servers; it still has serious security issues.

## Installing

Download
[the modpack](https://github.com/technomancy/calandria/releases/download/0.1.0-RC1/calandria-mp-0.1.0-RC1.tar.gz)
and place it in the `mods/` subdirectory of your Minetest
installation. See
[the wiki](http://wiki.minetest.com/wiki/Installing_Mods) for details
on installing mods.

In order to run the latest version from source, clone this repository
into your `mods/` subdirectory and grab
[orb](https://github.com/technomancy/orb) and
[diginet](https://github.com/technomancy/diginet) mods as well.

## Playing

![terminal](http://p.hagelb.org/calandria_terminal.png)

In order to start, you'll need to place a server block,
then place a terminal near it. Right-click on the terminal and log in
to the server using `/login (10,1,5) singleplayer` where the first
argument is the position of the server you've placed and the second
argument is your current player name. (Note that servers can have
users with any name, but when you place a server, the only user that
exists at first is one named after your player.) At that point you can
enter shell commands.

You can get reasonably far by just treating it like a unix with lots
of missing parts, but for a more thorough explanation see the
[orb readme](https://github.com/technomancy/orb).

![editor](http://p.hagelb.org/calandria_editor.png)

You can create simple files with `echo hello > greeting`, but for
larger files you are going to want to use a text editor node. Place it
and set the `server` field to the server on whose filesystem you want
to edit a file. Enter a path, and hit `load` to edit an existing file,
or just start typing and hit `save` to create a new one.

![dns](http://p.hagelb.org/calandria_dns.png)

Remembering the positions of your servers can be a bit of a drag. The
DNS server node from diginet allows you to add aliases for any given
position so you can just type an easy-to-remember name instead of a
bunch of numbers for the position.

No crafting recipes have been added yet, so you must use creative mode.

## Communication

Calandria servers include a few scripts to work with some 3rd-party mods.

    > flash /path/to/file (5,2,-17)

This allows you to remotely reprogram a
[Luacontroller](http://mesecons.net/luacontroller), from the
[Mesecons](http://mesecons.net/) mod. You can also use the `setports`
script to turn on and off its outputs:

    > setports (5,2,-17) true true false true

The Luacontroller at 5,2,-17 will have its A, B, and D ports turned on
and its C port turned off.

You can also send messages over the
[Digilines](https://github.com/Jeija/minetest-mod-digilines) protocol:

    > digiline mychannel message

Although digiline messages can be of any Lua type, the script only
supports string messages. To send non-strings, you can write your own
scripts that call the `digiline` function with channel and message arguments.

Terminals, servers, and editors communicate with each other using the
[diginet](https://github.com/technomancy/diginet) protocol, which has
some similarities to digilines, but is wireless and sends messages
without any propagation delay. You can create your own nodes which
accept diginet messages, and you can send diginet messages from
servers, either from your own programs or on the command line.

## Philosophy

In his 1980 book
[Mindstorms](https://www.goodreads.com/book/show/703532.Mindstorms),
Seymour Papert describes what he calls "Piagetian learning", which is
the process whereby children acquire language at a young age without
any formal instruction. Papert posits that cultures can teach certain
topics effortlessly as long as the culture is rich in concepts a
learner can appropriate and use to model the topic in their head, and
that classroom learning is introduced when the culture fails to
provide the means necessary to learn important topics.

The focus of his book is how the presence of a computer can provide
conceptual "materials" suitable for the construction of the kinds of
models that make acquiring mathematical knowledge come as naturally as
learning French comes to a child growing up in France; in fact the
metaphor of "growing up in Mathland" serves to illustrate how topics
which seem difficult when taught in a classroom setting can be learned
effortlessly when the surrounding culture provides the necessary
building blocks of knowledge.

The book describes labs in which children learn using
[Logo](https://en.wikipedia.org/wiki/Logo_%28programming_language%29),
a language allowing them to draw patterns on the screen by programming
a "turtle" avatar's motions. The turtle and its commands function as a
particularly apt source from which to build models of many aspects of
computation and mathematics, as he repeatedly demonstrates.

While this was groundbreaking at the time (and can still be used to
great effect) children now are already immersed in computer
environments without needing one to be introduced by educators. The
purpose of this project is take a voxel exploration game and turn it
into an environment which better serves to encourage Piagetian
learning, particularly about Unix and introductory programming.

## Prior Art

[ComputerCraft](http://computercraft.info/) is a mod for MineCraft
that has computer blocks as well as programmable turtles that can
manipulate the environment. However, it is not free software, nor is
the engine on which it runs, which renders it unsuitable for our
purposes. The terminal and editor it implements is very good, but the
OS is single-user.

[DroneTest](https://github.com/ninnghazad/dronetest) has programmable
computer nodes as well as drone entities that can move
around, but it does all its output by generating textures for the
display node every time it needs to change, and the Minetest engine
does not garbage collect old images. This means every DroneTest game
will eventually run out of memory. In addition, it does not implement
a terminal, relying instead on line-by-line commands. Also: the name
is cringe-worthy.

[Hoverbot](https://github.com/Pilcrow182/hoverbot) is another
programmable robot mod which uses visual drag-and-drop programming
similar to Scratch, but without loops or any higher-level features
than imperative commands.

[A Minetest pull request](https://github.com/minetest/minetest/pull/1737)
implements the ability to accept character-based input instead of
line-based input, but it has not been merged and hasn't seen any
activity since December of 2014. It is just the first prerequisite to
building a terminal in Minetest, but it looks promising.

The [Terminal](https://github.com/bas080/terminal) Minetest mod claims
to implement a terminal, but it doesn't. It only allows for shell
commands to be run using a line-based input, and streaming output to
the messages output.

It seems like implementing a terminal is going to be the biggest
technical challenge for this mod since no one has so far accomplished
this satisfactorily.

## Gotchas

Interacting with the terminal is
[not as nice as it should be](https://github.com/technomancy/calandria/issues/4). In
particular, when output comes in from a server, the input field is
cleared, and
[pressing enter closes the terminal](https://github.com/technomancy/calandria/issues/21). You
can work around the latter by pressing `tab` to focus the "enter" form
button, hitting enter, and hitting `shift-tab` to focus back on the
input field.

This mod is not suitable for public servers due to security concerns.
Currently logins to server nodes
[do not require a password](https://github.com/technomancy/orb/issues/7).
Also note that all chat commands run on a server node are run as the
player who placed that node, which is a definite security concern in
some contexts. Please note that it's easy to make
[programs which will bring Minetest to a halt](https://github.com/technomancy/calandria/issues/6).

## License

Copyright © 2015 Phil Hagelberg and contributors

Textures: [CC BY-SA 4.0](http://creativecommons.org/licenses/by-sa/4.0/)
Code: GPLv3 or later; see COPYING.


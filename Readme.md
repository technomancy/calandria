# Calandria

This is a game that uses the [Minetest engine](http://www.minetest.net) to
teach programming and other technical skills.

<img src="http://p.hagelb.org/calandria-shell.png" alt="shell screenshot" width="600" />

You are in a spaceship that has been damaged by asteroid impact. You're
trying to get home by repairing and operating vital ship systems.
There is a repair robot, but its programming has been destroyed in the
accident, so you need to reprogram it, among other things.

<img src="http://p.hagelb.org/calandria-corridor.png" alt="shell screenshot" width="600" />

## Playing

It is still *very* rough.

Download a copy of the game (either through `git clone` or
[as an archive](https://github.com/technomancy/calandria/archive/master.zip))
and place it in the `games/` subdirectory of your Minetest
installation. Launch Minetest and select the Calandria game at the
bottom (blue C icon with stars).

Create a new world in Creative mode. It will spawn you in a world with
a single block to stand on; you can build a ship out from there.

In order to start using the OS, you'll need to place a server block
first. Then place a terminal near it. Right-click on the terminal and
log in to the server using `/login (10,1,5) username` where the second
argument is the position of the server you've placed. At that point
you can enter shell commands.

There's also an unfinished
[pre-made world you can use](http://p.hagelb.org/calandria-ship.tar.gz).

You can use the OS from the CLI outside the game as well:

```
$ lua mods/orb/init.lua
```

However, when run this way it uses blocking input, which will prevent
the scheduler from running more than one process. (This means you
can't pipe from one process to another, as this requires at least some
level of faux-concurrency.)  Note the filesystem is purely in-memory
in the Lua process and will not persist when run from the CLI, though
when running in-game it should be persisted in between server
restarts.

## Repairs/Puzzles

Some samples of the challenges: (to implement in the future?)

* Restore power to a door
* Fix the robot (needs a power cell?)
* Bring main power back online
* Repair the hull (otherwise the oxygen will leak out)
* Fix life support (otherwise parts of the ship have no oxygen)

Some of these will involve simply placing blocks; some of them will
involve simply using the OS on the computer; some of them can't be
done without programming the main computer; some require programming
the robot.

## Ship

The ship is powered by a main power reactor with a backup solar array
for auxiliary power. There are a number of decks. Each deck will have
conduits running under it for bringing power and data channels to the
various systems.

Some areas of the ship have oxygen, but some are depressurized. The
robot can repair the hull breaches, and the oxygen system can pump
atmosphere into the breached rooms. It would be really cool if we
could model atmosphere as an invisible Minetest liquid, assuming we
can invert the normal damage logic.

A bunch of systems, including the robot, have been damaged. Some of
them you will need to get power to. When the game begins, the ship
will be running on auxiliary power, which doesn't have enough power to
activate all the ship's systems. Bringing main power online is a
significant goal. Power mechanics are inspired by FTL, but controlled
via a unixlike system.

Systems are broken up by decks; each deck has its own computer. Doors
and airlocks for each deck can be controlled by the deck computer if
powered, but also have a switch next to them that can be remotely
overridden.

<img src="http://p.hagelb.org/calandria-cargo-bay.png" alt="shell screenshot" width="600" />

### Command Deck

* Navigation
* Communication
* Shields
* Elevator

### Science Deck

* Sensors
* Lab
* Cargo Bay

### Habitat Deck

* Oxygen
* Gravity
* Mess hall
* Cabins

### Engineering Deck

* Reactor
* Engines
* Solar array
* Robotics

## OS

The ship's onboard computers will need an operating system. It should
be roughly Unix, supporting multiple users/groups and a filesystem,
but with metric time (a la Vinge).

You start out with access to your own user on a single computer via a
keypair. You only have access to a handful of diagnostic utilities. As
you progress, you can be added to new groups and gain private keys for
other users' accounts. You may start with access to the science
computer and need to gain access to engineering and command
separately.

### Executables

* [x] ls
* [x] cat
* [x] mkdir
* [x] env
* [x] cp
* [x] mv
* [x] rm
* [x] echo
* [x] smash (bash-like)
* [x] chmod
* [x] chown
* [x] chgrp
* [x] ps
* [x] grep
* [ ] man
* [ ] mail
* [ ] ssh
* [ ] scp
* [ ] sudo
* [ ] kill?
* [ ] more
* [ ] passwd

Other shell features

* [x] sandbox scripts (limited api access)
* [x] enforce access controls in the filesystem
* [x] input/output redirection
* [ ] pipes (half-implemented)
* [ ] globs
* [ ] env var interpolation
* [ ] quoting in shell args
* [ ] pre-emptive multitasking (see [this thread](https://forum.minetest.net/viewtopic.php?f=47&t=10185) for implementation ideas)
* [ ] /proc nodes for exposing connected digiline peripherals

* [ ] more of the built-in scripts should take multiple target arguments
* [ ] an editor (hoooo boy this is gonna be fun!)
* [ ] user passwords

Until we get an actual xterm with character input, we are probably
stuck with using a separate block for a (somewhat lame) editor.

### Differences from Unix

The OS is an attempt at being unix-like; however, it varies in several
ways. Some of them are due to conceptual simplification; some are in
order to have an easier time implementing it given the target
platform, and some are due to oversight/mistakes or unfinished features.

The biggest difference is that of permissions. In this system,
permissions only belong to directories, and files are simply subject
to the permissions of the directory containing them. In addition, the
[octal permissions](https://en.wikipedia.org/wiki/File_system_permissions#Notation_of_traditional_Unix_permissions)
of unix are collapsed into a single `group_write` bit. It's assumed
that the directory's owner always has full read-write access and that
members of the group always have read access. The `chown` and `chgrp`
commands work similarly as to unix, but `chmod` simply takes a `+` or
`-` argument to enable or disable group write. Group membership is
indicated simply by an entry in the `/etc/groups/$GROUP` directory
named after the username.

Rather than traditional stdio kept in `/dev/`, here we have `IN` and
`OUT` filenames kept in the environment, and `read` and `write`
default to using these. There is no stderr. Due to limitations
in the engine, there is no character-by-character IO; it is only full
strings (usually a whole line) at a time that are passed to `write` or
returned from `read`. The sandbox in which scripts run have `print`,
`io.write`, and `io.read` redefined to these functions; when a session
is initiated over the terminal it's up to the node definition to set
`IN` and `OUT` in the environment to functions which move the data
to and from the terminal's connection.

Of course, all scripts are written in Lua. Filesystem, the environment
table, and CLI args are exposed as `...`, so scripts typically start
with `local f, env, args = ...`. Filesystem access is simply table
access, though the table you're given is a proxy table that enforces
permissions with Lua metamethods. Regular files in the filesystem are
just strings in a table, and special nodes (like named pipes) are
functions.

Servers can have multiple processes running at once, but the shell
does not support multiplexing, so this is only possible through
connecting multiple terminals to a single server.

## Blocks

### Decorative

* [x] Steel blocks
* [x] Duranium (decorative alternative to steel)
* [x] Tritanium (decorative alternative to steel)
* [x] Glass
* [ ] Corridor arches
* [ ] Signs (can't be wooden)
* [ ] Damaged wires
* [x] Beds

### Electronic

* [x] Computers
* [x] Terminals
* [ ] Switches
* [ ] buttons
* [x] Wires (use mesecons)
* [ ] Indicators (light up when power/signal is on)
* [ ] Analog meters (shows how powerful a signal is)
* [ ] Power receptacle

### Powered blocks

* [x] Light panels
* [ ] Light columns
* [ ] Doors
* [ ] Airlocks
* [ ] Elevators

### Other

* [ ] Hatches
* [ ] Vents
* [ ] Debris
* [ ] Chairs
* [ ] Ladders
* [ ] Coolant (liquid)

* [x] Remove non-space blocks (axes, dirt, etc)

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

## License

Textures: [CC BY-SA 4.0](http://creativecommons.org/licenses/by-sa/4.0/)
Sky textures from [Moontest](https://github.com/Amaz1/moontest).

Calandria-specific code (calandria/orb mods): GPLv3 or later; see COPYING.
Other bundled mods distributed under their own licenses as documented.

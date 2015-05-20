# Calandria

This is a game that uses the [MineTest engine](http://www.minetest.net) to
teach programming and other technical skills.

<img src="http://p.hagelb.org/calandria-shell.png" alt="shell screenshot" width="600" />

You are in a spaceship that has been damaged by asteroid impact. You're
trying to get home by repairing and operating vital ship systems.
There is a repair robot, but its programming has been destroyed in the
accident, so you need to reprogram it, among other things.

<img src="http://p.hagelb.org/calandria-corridor.png" alt="shell screenshot" width="600" />

## Repairs/Puzzles

Some samples of the challenges:

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
conduits running under it for bringing power to the various
systems. Normally you would travel between decks with the elevators,
but with main power offline you would need to climb ladders in shafts.

Some areas of the ship have oxygen, but some are depressurized. The
robot can repair the hull breaches, and the oxygen system can pump
atmosphere into the breached rooms. It would be really cool if we
could model atmosphere as an invisible MineTest liquid, assuming we
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
* [x] cd
* [x] cat
* [x] mkdir
* [x] env
* [x] cp
* [x] mv
* [x] rm
* [x] echo
* [x] export
* [x] smash (bash-like)
* [ ] chmod
* [ ] chown
* [ ] an editor (hoooo boy this is gonna be fun!)
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
* [ ] enforce access controls in the filesystem
* [ ] globs
* [ ] env var interpolation
* [ ] quoting in shell args
* [ ] pre-emptive multitasking (see [this thread](https://forum.minetest.net/viewtopic.php?f=47&t=10185) for implementation ideas)

### Security

Need to sandbox in orb.shell.exec, but this still causes problems as
the env table can be modified. Do we send a copy of this table to
scripts? Then export needs to become a primitive. (which it is in bash
anyway, nbd.)

Then there's the question of reading, writing, and executing with the
filesystem. Maybe scripts need a wrapped copy of the fs which only
exposes the nodes for which the user has access?

Private and public keys are inventory items. Placing a public key in a
server inventory will allow the holder of the private key to log on.

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

* [ ] Computers
* [ ] Terminals
* [ ] Drives? (or the computer has an inventory)
* [x] Switches (use mesecons)
* [x] buttons (use mesecons)
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

* [ ] Remove non-space blocks (axes, dirt, etc)

## New items

* Private key
* Public key
* Power cells

## Prior Art

[ComputerCraft](http://computercraft.info/) is a mod for MineCraft
that has computer blocks as well as programmable turtles that can
manipulate the environment. However, it is not free software, nor is
the engine on which it runs, which renders it unsuitable for our
purposes. The terminal and editor it implements is very good, but the
OS is single-user.

[DroneTest](https://github.com/ninnghazad/dronetest) has programmable
computer nodes as well as drone entities that can move
around. However, it does all its output by generating textures for the
display node every time it needs to change, and the MineTest engine
does not garbage collect old images. This means every DroneTest game
will eventually run out of memory. In addition, it does not implement
a terminal, relying instead on line-by-line commands. Plus I couldn't
get it working on my own machine. Also: the name is cringe-worthy.

[A MineTest pull request](https://github.com/minetest/minetest/pull/1737)
implements the ability to accept character-based input instead of
line-based input, but it has not been merged and hasn't seen any
activity since December of 2014. It is just the first prerequisite to
building a terminal in MineTest, but it looks promising.

The [Terminal](https://github.com/bas080/terminal) MineTest mod claims
to implement a terminal, but it doesn't. It only allows for shell
commands to be run using a line-based input, and streaming output to
the messages output.

It seems like implementing a terminal is going to be the biggest
technical challenge for this mod since no one has so far accomplished
this satisfactorily.

## License

Textures: [CC BY-SA 4.0](http://creativecommons.org/licenses/by-sa/4.0/)
Sky textures from [Moontest](https://github.com/Amaz1/moontest).

Code: GPLv3

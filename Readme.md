# Calandria

This is a game that uses the [MineTest engine](http://www.minetest.net) to
teach programming and other technical skills.

You are in a spaceship that has been damaged by asteroid impact. You're
trying to get home by repairing and operating vital ship systems.
There is a repair robot, but its programming has been destroyed in the
accident, so you need to reprogram it, among other things.

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

The ship should have an onboard computer. (or three?
command/engineering/science?) The computers need an operating
system. It should be roughly Unix, supporting multiple users and a
filesystem, but with metric time (a la Vinge).

You start out with access to your own user on a single computer via a
keypair. You only have access to a handful of diagnostic utilities. As
you progress, you can be added to new groups and gain private keys for
other users' accounts. You may start with access to the science
computer and need to gain access to engineering and command separately.

Some areas of the ship have oxygen, but some are depressurized. The
robot can repair the hull breaches, and the oxygen system can pump
atmosphere into the breached rooms.

A bunch of systems, including the robot, have been damaged. Some of
them you will need to get power to. When the game begins, the ship
will be running on auxiliary power, which doesn't have enough power to
activate all the ship's systems. Bringing main power online is a
significant goal. Power mechanics are inspired by FTL, but controlled
via a unixlike system.

The OS should have an email setup as well as lots of man pages.

## Ship systems

* Doors
* Reactor
* Shields
* Navigation
* Sensors
* Gravity
* Oxygen
* Communication

## OS Executables

* [x] ls
* [ ] cd
* [ ] cat
* [ ] mkdir
* [ ] cp
* [ ] mv
* [ ] rm
* [ ] smash (bash-like)
* [ ] an editor (hoooo boy this is gonna be fun!)
* [ ] chmod
* [ ] chown
* [ ] man
* [ ] mail
* [ ] ssh
* [ ] scp
* [ ] sudo
* [ ] kill?
* [ ] more
* [ ] passwd

## Blocks

* [x] Steel blocks
* [x] Duranium (decorative alternative to steel)
* [x] Tritanium (decorative alternative to steel)
* [x] Glass
* [ ] Computers
* [ ] Drives? (or the computer has an inventory)
* [x] Switches (use mesecons)
* [x] buttons (use mesecons)
* [x] Wires (use mesecons)
* [ ] Doors
* [ ] Corridor arches
* [x] Light panels
* [ ] Debris
* [ ] Elevators
* [ ] Damaged circuits
* [ ] Power receptacle

## New items

* Private key
* Public key
* Power cells
* Sonic screwdriver

## License

Textures: [CC BY-SA 4.0](http://creativecommons.org/licenses/by-sa/4.0/)
Sky textures from [Moontest](https://github.com/Amaz1/moontest).

Code: GPLv3

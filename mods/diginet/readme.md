# Diginet

While Digilines is a great low-level protocol allowing for simple
communication between nodes, sometimes a little more structure is helpful.

If you think of Digilines as roughly between the level of Ethernet and
TCP, Diginet is an application-level protocol more like HTTP, though
it has to introduce a notion of addressing as this is absent from Digilines.

## Addressing

Position strings (defined as per `minetest.pos_to_string`) function as
addresses for nodes; as such they contain X, Y, and Z
coordinates. Addresses may also include wildcards or ranges in order
to function as broadcast or multicast.

* `(12,85,-12)` - addresses a single node
* `(*,*,*)` - addresses all nodes in a network
* `(*,0-255,*)` - addresses all nodes from Y=0 to Y=255

## Packets

Each packet is a lua table with three required fields:

* `source`: an address
* `destination`: an address
* `method`: what action this packet is intended to achieve

Optional fields include:

* `player`: the player who initiated the packet, if applicable
* `request_id`: if you expect a response, include a UUID (etc) in this field
* `in_reply_to`: when replying to a packet with a request id, place the id in this field of the response

Though of course you can include whatever fields you like.

## Ping

All Diginet-aware nodes should reply to ping packets:

    {source="(12,-5,23)", destination="(*,*,*)", method="ping"}

Responses should include `method="pong"` as well as a list of all
methods which the given node will respond.

    {source="(19,0,-10)", destination="(12,-5,23)", method="pong",
     methods={"ping", "open", "close", "toggle"}}

Replying to pings will be handled by the diginet library as long as
you define all your packet handlers declaratively so that diginet can
calculate the methods with which to respond.

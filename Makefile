check:
	luacheck --no-color -g *.lua

modpack:
	mkdir -p calandria-mp/mods
	git clone --depth=1 git@github.com:technomancy/calandria.git calandria-mp/mods/calandria
	git clone --depth=1 git@github.com:technomancy/diginet.git calandria-mp/mods/diginet
	git clone --depth=1 git@github.com:technomancy/orb.git calandria-mp/mods/orb
	rm -r calandra-mp/mods/*/.git
	mkdir calandria-mp/modpack.txt
	tar czf calandria-mp.tar.gz calandria-mp

upload: calandria-mp.tar.gz
	scp calandria-mp.tar.gz calandria.technomancy.us:calandria/

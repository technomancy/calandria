check:
	luacheck --no-color -g *.lua

modpack:
	mkdir -p calandria-mp/mods
	git clone --depth=1 git@github.com:technomancy/calandria.git calandria-mp/mods/calandria
	git clone --depth=1 git@github.com:technomancy/diginet.git calandria-mp/mods/diginet
	git clone --depth=1 git@github.com:technomancy/orb.git calandria-mp/mods/orb
	rm -r calandria-mp/mods/calandria/.git
	rm -r calandria-mp/mods/orb/.git
	rm -r calandria-mp/mods/diginet/.git
	touch calandria-mp/modpack.txt
	tar czf calandria-mp.tar.gz calandria-mp

upload: calandria-mp.tar.gz
	scp calandria-mp.tar.gz calandria.technomancy.us:calandria/

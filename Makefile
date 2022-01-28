install:
	sudo apt-get update
	sudo apt install tidy cmake

	# Install luarocks before - https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-Unix
	sudo luarocks install luacheck
	sudo luarocks install --server=https://luarocks.org/dev luaformatter

# TODO: Do recursive search for .lua and .xml files
fmt:
	lua-format -c .luaformatconfig -i src/*.lua
	tidy -config .tidyconfig -m src/*.xml

lint:
	luacheck src/*.lua
	tidy -config .tidyconfig -e src/*.xml

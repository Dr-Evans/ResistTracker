install:
	# TODO: Add lua-format and luacheck
	sudo apt install tidy

# TODO: Do recursive
fmt:
	lua-format -i src/*.lua
	tidy -config .tidyconfig -m src/*.xml

lint:
	luacheck src/*.lua
	tidy -config .tidyconfig -e src/*.xml

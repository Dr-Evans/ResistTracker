install:
	# TODO: Added lua-format and luacheck
	sudo apt install tidy

fmt:
	lua-format *.lua -i
	tidy -config .tidyconfig -m *.xml

lint:
	luacheck *.lua
	tidy -config .tidyconfig -e *.xml

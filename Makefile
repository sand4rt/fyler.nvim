.PHONY: all fmt lint test

all: fmt lint test

fmt:
	stylua lua --config-path=.stylua.toml

lint:
	luacheck lua --globals vim

test:
	nvim -l scripts/minitest.lua

docgen:
	nvim --headless --noplugin -u scripts/minit.lua -c "luafile ./scripts/docgen.lua" -c 'qa'

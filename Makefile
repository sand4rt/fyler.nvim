.PHONY: check format lint test

check: format lint test

format:
	stylua lua tests --config-path=.stylua.toml

lint:
	luacheck lua --globals vim

test:
	nvim -l scripts/minitest.lua

.PHONY: check format lint test

check: format lint test

format:
	stylua .

lint:
	selene --config selene/config.toml lua

test:
	nvim -l tests/init.lua

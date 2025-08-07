.SILENT:
.PHONY: check format lint test

check: format lint test

format:
	@printf "\033[34mFYLER.NVIM - Code Formatting\033[0m\n\033[34m────────────────────────────\033[0m\n"
	@stylua . 2>/dev/null && printf "\n\033[32mCode formatted\033[0m\n\n" || (printf "\n\033[31mFormatting failed\033[0m\n\n"; exit 1)

lint:
	@printf "\033[34mFYLER.NVIM - Code Linting\033[0m\n\033[34m────────────────────────────\033[0m\n"
	@selene --config selene/config.toml lua 2>/dev/null && printf "\n\033[32mLinting passed\033[0m\n\n" || (printf "\n\033[31mLinting failed\033[0m\n\n"; exit 1)

test:
	@printf "\033[34mFYLER.NVIM - Running Tests\033[0m\n\033[34m────────────────────────────\033[0m\n"
	@nvim -l tests/init.lua

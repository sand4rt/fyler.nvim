.SILENT:
.PHONY: check format lint test spec doc

check: format lint test spec doc

format:
	@printf "\033[34mFYLER.NVIM - Code Formatting\033[0m\n\033[34m────────────────────────────\033[0m\n"
	@stylua . 2>/dev/null && printf "\n\033[32mCode formatted\033[0m\n\n" || (printf "\n\033[31mFormatting failed\033[0m\n\n"; exit 1)

lint:
	@printf "\033[34mFYLER.NVIM - Code Linting\033[0m\n\033[34m────────────────────────────\033[0m\n"
	@selene --config selene/config.toml lua 2>/dev/null && printf "\n\033[32mLinting passed\033[0m\n\n" || (printf "\n\033[31mLinting failed\033[0m\n\n"; exit 1)

test:
	@printf "\033[34mFYLER.NVIM - Running Tests\033[0m\n\033[34m────────────────────────────\033[0m\n"
	@nvim -l bin/run_unit_tests.lua

spec:
	@printf "\033[34mFYLER.NVIM - E2E Tests\033[0m\n\033[34m────────────────────────────\033[0m\n"
	@python3 bin/run_e2e_tests.py

doc:
	@printf "\033[34mFYLER.NVIM - Generating vim docs\033[0m\n\033[34m────────────────────────────\033[0m\n"
	@nvim -l bin/gen_vimdoc.lua

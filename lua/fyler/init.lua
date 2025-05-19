local M = {}

function M.setup()
	vim.api.nvim_create_user_command("Fyler", function()
		print("Hello from Fyler setup!")
	end, { nargs = 0 })
end

return M

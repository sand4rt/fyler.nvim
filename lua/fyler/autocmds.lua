local M = {}

local api = vim.api
local uv = vim.uv or vim.loop

function M.setup()
  api.nvim_create_autocmd("ColorScheme", {
    group = require("fyler").augroup,
    callback = function()
      require("fyler.lib.hls").setup()
    end,
  })

  api.nvim_create_autocmd("BufEnter", {
    group = require("fyler").augroup,
    callback = function(arg)
      local stats = uv.fs_stat(arg.file)
      if stats and stats.type == "directory" then
        local cur_buf = api.nvim_get_current_buf()
        if api.nvim_buf_is_valid(cur_buf) then
          api.nvim_buf_delete(cur_buf, { force = true })
        end

        require("fyler").open { cwd = arg.file }
      end
    end,
  })
end

return M

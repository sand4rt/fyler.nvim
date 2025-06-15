local M = {}

local api = vim.api

function M.setup()
  api.nvim_create_autocmd("ColorScheme", {
    group = require("fyler").augroup,
    callback = function()
      require("fyler.lib.hls").setup()
    end,
  })
end

return M

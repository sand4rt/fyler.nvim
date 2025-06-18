local M = {}

local api = vim.api

function M.setup()
  api.nvim_create_autocmd("ColorScheme", {
    group = require("fyler").augroup,
    callback = function()
      require("fyler.lib.hls").setup()
    end,
  })

  api.nvim_create_autocmd("BufWriteCmd", {
    pattern = "file_tree",
    group = require("fyler").augroup,
    callback = function(arg)
      api.nvim_exec_autocmds("User", { pattern = "Synchronize" })

      vim.bo[arg.buf].modified = false
    end,
  })

  api.nvim_create_autocmd("BufReadCmd", {
    pattern = "file_tree",
    group = require("fyler").augroup,
    callback = function(arg)
      api.nvim_exec_autocmds("User", { pattern = "RefreshView" })

      vim.bo[arg.buf].filetype = "fyler"
      vim.bo[arg.buf].syntax = "fyler"
    end,
  })
end

return M

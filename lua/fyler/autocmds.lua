local util = require "fyler.lib.util"

local M = {}
local api = vim.api

-- Autogroup for global autocommands controlled by "Fyler.nvim"
local augroup = api.nvim_create_augroup("Fyler-augroup-global", { clear = true })

-- Setup autocommands with respect to configuration
function M.setup(config)
  config = config or {}

  -- Only replace NETRW commands when mentioned
  if config.values.default_explorer then
    vim.cmd "silent! autocmd! FileExplorer *"
    vim.cmd "autocmd VimEnter * ++once silent! autocmd! FileExplorer *"

    api.nvim_create_autocmd("BufEnter", {
      group = augroup,
      pattern = "*",
      desc = "Hijack NETRW commands",
      callback = function(arg)
        if api.nvim_get_current_buf() ~= arg.buf then return end

        local path = api.nvim_buf_get_name(0)
        if vim.fn.isdirectory(path) ~= 1 then return end

        api.nvim_buf_delete(0, { force = true })
        require("fyler").open { dir = path }
      end,
    })
  end

  -- Adjust highlight groups with respect to "colorscheme"
  api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    desc = "Adjust highlight groups with respect to colorscheme",
    callback = function() require("fyler.lib.hls").setup() end,
  })

  -- -- Track current focused buffer in explorer
  if config.values.track_current_buffer then
    api.nvim_create_autocmd("BufEnter", {
      group = augroup,
      desc = "Track current focused buffer in explorer",
      callback = function(arg)
        local instance = require("fyler.explorer").current()
        if instance then util.debounce("focus_buffer", function() instance:_action "track_buffer"(arg) end, 10) end
      end,
    })
  end

  -- Drop explorer window when buffer inside it changes to "NON FYLER BUFFER"
  api.nvim_create_autocmd("BufWinEnter", {
    group = augroup,
    desc = "Drop explorer window when buffer inside it changes to NON FYLER BUFFER",
    callback = function(arg)
      local instance = require("fyler.explorer").current()

      if not instance then return end
      if not instance.win:has_valid_winid() then return end

      local bufnr = arg.buf
      local bufname = api.nvim_buf_get_name(bufnr)
      if bufname:match "^fyler://*" then return end
      if api.nvim_win_get_buf(instance.win.winid) == bufnr then instance.win:recover() end
    end,
  })
end

return M

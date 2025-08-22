local util = require("fyler.lib.util")

local M = {}

local api = vim.api
local fn = vim.fn

-- Autogroup for global autocommands controlled by "Fyler.nvim"
local augroup = api.nvim_create_augroup("Fyler", { clear = true })

-- Setup autocommands with respect to configuration
function M.setup(config)
  config = config or {}

  -- Only replace NETRW commands when mentioned
  if config.values.views.explorer.default_explorer then
    vim.cmd("silent! autocmd! FileExplorer *")
    vim.cmd("autocmd VimEnter * ++once silent! autocmd! FileExplorer *")

    api.nvim_create_autocmd("BufEnter", {
      group = augroup,
      pattern = "*",
      desc = "Hijack NETRW commands",
      callback = function(arg)
        if vim.api.nvim_get_current_buf() ~= arg.buf then return end

        local path = vim.api.nvim_buf_get_name(0)
        if vim.fn.isdirectory(path) ~= 1 then return end

        util.set_buf_option(0, "bufhidden", "wipe")
        require("fyler").open { cwd = path }
      end,
    })
  end

  -- Set window syntax when "FylerWinOpen" event gets triggered
  api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "FylerWinOpen",
    desc = "Add Fyler.Explorer syntax",
    callback = function(arg)
      if not (arg.data.bufname and arg.data.bufname:match("fyler://*")) then return end

      api.nvim_win_call(arg.data.win, function()
        util.set_win_option(0, "concealcursor", "nvic")
        util.set_win_option(0, "conceallevel", 3)
        fn.matchadd("Conceal", [[/\d\d\d\d\d ]])
      end)
    end,
  })

  -- Adjust highlight groups with respect to "colorscheme"
  api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    desc = "Adjust highlight groups with respect to colorscheme",
    callback = function() require("fyler.lib.hls").setup() end,
  })

  -- Track current focused buffer in explorer
  api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    desc = "Track current focused buffer in explorer",
    callback = function(arg)
      local instance = require("fyler.views.explorer").instance
      if instance then instance:_action("try_focus_buffer")(arg) end
    end,
  })

  -- Drop explorer window when buffer inside it changes to "NON FYLER BUFFER"
  api.nvim_create_autocmd("BufWinEnter", {
    group = augroup,
    desc = "Drop explorer window when buffer inside it changes to NON FYLER BUFFER",
    callback = function(arg)
      local instance = require("fyler.views.explorer").instance
      if not instance then return end
      if not instance.win:has_valid_winid() then return end

      local bufnr = arg.buf
      local bufname = api.nvim_buf_get_name(bufnr)
      if bufname:match("^fyler://*") then return end
      if api.nvim_win_get_buf(instance.win.winid) == bufnr then instance.win:recover() end
    end,
  })
end

return M

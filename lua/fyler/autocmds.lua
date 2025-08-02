local util = require("fyler.lib.util")

local M = {}

local api = vim.api
local fn = vim.fn
local uv = vim.uv or vim.loop

local augroup = api.nvim_create_augroup("Fyler", { clear = true })

function M.setup(config)
  config = config or {}

  if config.values.views.explorer.default_explorer then
    vim.cmd("silent! autocmd! FileExplorer *")
    vim.cmd("autocmd VimEnter * ++once silent! autocmd! FileExplorer *")

    api.nvim_create_autocmd("BufEnter", {
      group = augroup,
      pattern = "*",
      callback = function(arg)
        if vim.api.nvim_get_current_buf() ~= arg.buf then return end

        local path = vim.api.nvim_buf_get_name(0)
        if vim.fn.isdirectory(path) ~= 1 then return end

        vim.bo.bufhidden = "wipe"

        require("fyler").open { path = path }
      end,
    })
  end

  api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    pattern = "fyler://*",
    callback = function(arg)
      api.nvim_win_call(fn.bufwinid(arg.buf), function()
        vim.wo.concealcursor = "nvic"
        vim.wo.conceallevel = 3

        fn.matchadd("Conceal", [[/\d\d\d\d\d ]])
        fn.matchadd("Conceal", [[/\d\d\d\d\d [^/]*\zs/\ze]])
      end)
    end,
  })

  api.nvim_create_autocmd(
    "ColorScheme",
    { group = augroup, callback = function() require("fyler.lib.hls").setup() end }
  )

  api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function(...)
      local cur_instance = require("fyler.views.explorer").instance
      if cur_instance then cur_instance:_action("try_focus_buffer")(...) end
    end,
  })

  api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = vim.schedule_wrap(function(arg)
      local explorer = require("fyler.views.explorer").instance
      if not explorer then return end

      if vim.fn.bufname(arg.buf) == explorer.win.bufname then return end

      if api.nvim_get_current_win() == explorer.win.winid then
        for option, _ in pairs(require("fyler.config").get_view("explorer").win.win_opts) do
          if not util.has_valid_winid(explorer.win) then return end

          vim.wo[explorer.win.winid][option] = vim.w[explorer.win.winid][option]
        end
      end
    end),
  })

  if config.values.views.explorer.default_explorer then
    api.nvim_create_autocmd("BufEnter", {
      group = augroup,
      callback = function(arg)
        local stats = uv.fs_stat(arg.file)

        if stats and stats.type == "directory" then
          local cur_buf = api.nvim_get_current_buf()

          if api.nvim_buf_is_valid(cur_buf) then api.nvim_buf_delete(cur_buf, { force = true }) end

          require("fyler").open { cwd = arg.file }
        end
      end,
    })
  end
end

return M

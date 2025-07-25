local M = {}

local api = vim.api
local uv = vim.uv or vim.loop

local augroup = api.nvim_create_augroup("Fyler", { clear = true })

function M.setup(opts)
  opts = opts or {}

  api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = function()
      require("fyler.lib.hls").setup()
    end,
  })

  api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function(...)
      local cur_instance = require("fyler.views.explorer").instance
      if cur_instance then
        cur_instance:_action("try_focus_buffer")(...)
      end
    end,
  })

  if opts.values.default_explorer then
    api.nvim_create_autocmd("BufEnter", {
      group = augroup,
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
end

return M

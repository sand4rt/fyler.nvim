local M = {}

local did_setup = false

local api = vim.api
local fn = vim.fn

---@param opts FylerConfig
function M.setup(opts)
  if vim.fn.has("nvim-0.11") ~= 1 then
    return vim.notify("Fyler requires at least NVIM 0.11")
  end

  if did_setup then
    return
  end

  require("fyler.config").setup(opts)
  require("fyler.lib.hls").setup()
  require("fyler.autocmds").setup()

  if require("fyler.config").values.default_explorer then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    if fn.exists("#FileExplorer") then
      api.nvim_create_augroup("FileExplorer", { clear = true })
    end

    if vim.v.vim_did_enter == 0 then
      local arg_path = fn.argv(0)
      local first_arg = type(arg_path) == "string" and arg_path or arg_path[1]
      if fn.isdirectory(first_arg) == 0 then
        return
      end

      local current_bufnr = api.nvim_get_current_buf()
      if api.nvim_buf_is_valid(current_bufnr) then
        api.nvim_buf_delete(current_bufnr, { force = true })
      end

      vim.schedule(function()
        M.open { cwd = arg_path }
      end)
    end
  end

  did_setup = true
end

function M.open(opts)
  opts = opts or {}

  require("fyler.views.explorer").open {
    cwd = opts.cwd,
    kind = opts.kind,
  }
end

return M

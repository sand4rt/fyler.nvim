local M = {}

local did_setup = false

---@param opts FylerConfig
function M.setup(opts)
  if vim.fn.has("nvim-0.11") ~= 1 then return vim.notify("Fyler requires at least NVIM 0.11") end
  if did_setup then return end

  require("fyler.config").setup(opts)
  require("fyler.lib.hls").setup(require("fyler.config"))
  require("fyler.autocmds").setup(require("fyler.config"))

  did_setup = true
end

M.open = vim.schedule_wrap(function(opts) require("fyler.views.explorer").open(opts) end)

return M

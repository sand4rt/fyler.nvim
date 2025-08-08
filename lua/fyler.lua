local M = {}

local did_setup = false

---@param custom_config FylerConfig
function M.setup(custom_config)
  if vim.fn.has("nvim-0.11") ~= 1 then return vim.notify("Fyler requires at least NVIM 0.11") end
  if did_setup then return end

  local config = require("fyler.config")
  config.setup(custom_config)

  require("fyler.autocmds").setup(config)
  require("fyler.hooks").setup(config)
  require("fyler.lib.hls").setup(config)

  did_setup = true

  local util = require("fyler.lib.util")
  local fs = require("fyler.lib.fs")

  M.open = vim.schedule_wrap(
    function(opts)
      require("fyler.views.explorer").open(util.tbl_merge_keep(opts or {}, {
        cwd = fs.getcwd(),
        enter = true,
        kind = config.get_view_config("explorer").win.kind,
      }))
    end
  )
end

return M

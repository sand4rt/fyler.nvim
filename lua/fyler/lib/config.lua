---@class Fyler.Config
---@field close_on_open boolean
---@field default_explorer boolean
---@field window_config Fyler.Config.WindowConfig
---@field window_options Fyler.Config.WindowOptions
---@field view_config Fyler.Config.ViewConfig

---@class Fyler.Config.WindowConfig
---@field width number
---@field split
---| "left"
---| "above"
---| "right"
---| "below"

---@class Fyler.Config.WindowOptions
---@field number boolean
---@field relativenumber boolean

---@class Fyler.Config.ViewConfig
---@field git_status { enable: boolean }

local M = {}
local defaults = {
  close_on_open = true,
  default_explorer = false,
  window_config = {
    width = 0.3,
    split = 'right',
  },
  window_options = {
    number = true,
    relativenumber = true,
  },
  view_config = {
    git_status = {
      enable = true,
    },
  },
}

---@param options Fyler.Config
function M.set_defaults(options)
  M.values = vim.tbl_deep_extend('force', defaults, options or {})
end

return M

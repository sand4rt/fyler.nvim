---@class IconIntegration
---@field mini_icon MiniIconsIntegration
---@field nvim_web_devicons NvimWebDeviconsIntegration
local M = {}

setmetatable(M, {
  __index = function(_, k)
    local icon_provider = require("fyler.integrations.icon." .. k)

    return function(type, path) return icon_provider.get(type, path) end
  end,
})

return M

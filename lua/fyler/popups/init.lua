---@class Popup
---@field permission PopupPermission
local Popup = {}

setmetatable(Popup, {
  __index = function(_, k) return require("fyler.popups." .. k) end,
})

return Popup

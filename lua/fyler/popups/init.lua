---@class Popup
---@field permission PopupPermission
local Popup = {}

setmetatable(Popup, {
  __index = function(_, k)
    local ok, popup = pcall(require, "fyler.popups." .. k)
    assert(ok, string.format("Popup not found with name %s", k))

    return popup
  end,
})

return Popup

---@class Fyler.Window.Options
---@field col?          number
---@field row?          number
---@field enter         boolean
---@field width         number
---@field split?
---| "top"
---| "left"
---| "right"
---| "bottom"
---@field height?       number
---@field border?       string
---@field col_delta?    integer
---@field row_delta?    integer
---@field width_delta?  integer
---@field height_delta? integer

---@class Fyler.Window : Fyler.Window.Options
---@field bufnr? integer
---@field winid? integer
local Window = {}
Window.__index = Window

---@param options Fyler.Window.Options
---@return Fyler.Window
function Window.new(options)
  return setmetatable({}, Window):init(options)
end

---@param options Fyler.Window.Options
---@return Fyler.Window
function Window:init(options)
  for k, v in pairs(options or {}) do
    self[k] = v
  end

  return self
end

return Window

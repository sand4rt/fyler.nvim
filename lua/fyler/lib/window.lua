---@class Fyler.Window.Options
---@field width number
---@field height? number
---@field width_delta? integer
---@field height_delta? integer
---@field col? number
---@field row? number
---@field col_delta? integer
---@field row_delta? integer
---@field split? "top"|"right"|"bottom"|"left"
---@field border? string
---@field enter boolean

---@class Fyler.Window : Fyler.Window.Options
---@field bufnr? integer
---@field winid? integer
local Window = {}

---@param options Fyler.Window.Options
---@return Fyler.Window
function Window.new(options)
  return setmetatable({}, {
    __index = Window,
  }):init(options)
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

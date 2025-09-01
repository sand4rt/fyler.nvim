---@alias UiLineAlign
---| "end"
---| "start"
---| "center"

---@alias UiWord { str: string, hl: string|nil }
---@alias UiMark { str: string, hl: string|nil, id: string }

---@class UiLine
---@field align UiLineAlign
---@field words UiWord[]
---@field marks UiMark[]
local Line = {}
Line.__index = Line

---@param opts { words: UiWord[], marks: UiMark[], align: UiLineAlign|nil }
---@return UiLine
function Line.new(opts)
  local instance = {
    words = opts.words or {},
    align = opts.align or "start",
    marks = opts.marks or {},
  }

  setmetatable(instance, Line)

  return instance
end

return { Line = Line }

---@alias FylerUiLineAlign
---| "end"
---| "start"
---| "center"

---@alias FylerUiWord { str: string, hl: string|nil }
---@alias FylerUiMark { str: string, hl: string|nil, id: string }

---@class FylerUiLine
---@field align FylerUiLineAlign
---@field words FylerUiWord[]
---@field marks FylerUiMark[]
local Line = {}
Line.__index = Line

---@param opts { words: FylerUiWord[], marks: FylerUiMark[], align: FylerUiLineAlign|nil }
---@return FylerUiLine
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

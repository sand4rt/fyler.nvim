---@alias FylerUiLineAlign
---| "end"
---| "start"
---| "center"

---@alias FylerUiWord { str: string, hl?: string }
---@alias FylerUiMark { str: string, hl?: string, id: string }

---@class FylerUiLine
---@field align FylerUiLineAlign
---@field words FylerUiWord[]
---@field marks FylerUiMark[]
local Line = {}
Line.__index = Line

return {
  Line = setmetatable({}, {
    ---@param opts { words: FylerUiWord[], marks: FylerUiMark[], align?: FylerUiLineAlign }
    ---@return FylerUiLine
    __call = function(_, opts)
      local instance = {
        words = opts.words or {},
        align = opts.align or "start",
        marks = opts.marks or {},
      }

      setmetatable(instance, Line)

      return instance
    end,
  }),
}

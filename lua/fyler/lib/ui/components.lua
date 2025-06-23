---@class FylerUiWord
---@field str string
---@field hl  string
local Word = {}
Word.__index = Word

---@class FylerUiMark
---@field str string
---@field hl  string
---@field id  number
local Mark = {}
Mark.__index = Mark

---@alias FylerUiLineAlign
---| "end"
---| "start"
---| "center"

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
  Word = setmetatable({}, {
    ---@param str string
    ---@param hl? string
    ---@return FylerUiWord
    __call = function(_, str, hl)
      return setmetatable({ str = str, hl = hl or "FylerBlank" }, Word)
    end,
  }),
  Mark = setmetatable({}, {
    ---@param str string
    ---@param hl  string
    ---@param id  number
    ---@return FylerUiMark
    __call = function(_, str, hl, id)
      return setmetatable({ str = str, hl = hl or "FylerBlank", id = id }, Mark)
    end,
  }),
}

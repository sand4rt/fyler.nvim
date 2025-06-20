---@class FylerUiWord
---@field str string
---@field hl  string
local Word = {}
Word.__index = Word

---@alias FylerUiLineAlign
---| "end"
---| "start"
---| "center"

---@class FylerUiLine
---@field align FylerUiLineAlign
---@field words FylerUiWord[]
local Line = {}
Line.__index = Line

return {
  Line = setmetatable({}, {
    ---@param opts { words: FylerUiWord[], align?: FylerUiLineAlign }
    ---@return FylerUiLine
    __call = function(_, opts)
      local instance = { words = opts.words or {}, align = opts.align or "start" }

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
}

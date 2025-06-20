---@class FylerUiWord
---@field str string
---@field hl  string
local Word = {}
Word.__index = Word

---@param str string
---@param hl? string
---@return FylerUiWord
function Word.new(str, hl)
  return setmetatable({ str = str, hl = hl or "FylerBlank" }, Word)
end

---@alias FylerUiLineAlign
---| "end"
---| "start"
---| "center"

---@class FylerUiLine
---@field align FylerUiLineAlign
---@field words FylerUiWord[]
local Line = {}
Line.__index = Line

---@param opts { words: FylerUiWord[], align?: FylerUiLineAlign }
---@return FylerUiLine
function Line.new(opts)
  local instance = { words = opts.words or {}, align = opts.align or "start" }

  setmetatable(instance, Line)

  return instance
end

return {
  Line = Line,
  Word = Word,
}

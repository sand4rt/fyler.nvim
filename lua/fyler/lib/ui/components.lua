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

---@class FylerUiLine
---@field words FylerUiWord[]
local Line = {}
Line.__index = Line

---@param words? FylerUiWord[]
---@return FylerUiLine
function Line.new(words)
  local instance = { words = words or {} }

  setmetatable(instance, Line)

  return instance
end

return {
  Line = Line,
  Word = Word,
}

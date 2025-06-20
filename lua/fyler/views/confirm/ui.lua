local components = require("fyler.lib.ui.components")

local Line = components.Line
local Word = components.Word

local function MESSAGE(tbl)
  local lines = {}
  for _, line in ipairs(tbl or {}) do
    table.insert(
      lines,
      Line.new {
        words = vim.tbl_map(function(word)
          return Word.new(word.str, word.hl)
        end, line),
      }
    )
  end

  return lines
end

local M = {}

---@param tbl table
function M.Confirm(tbl)
  if not tbl then
    return {}
  end

  return MESSAGE(tbl)
end

return M

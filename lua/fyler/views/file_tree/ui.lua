local components = require("fyler.lib.ui.components")

local Line = components.Line
local Word = components.Word

local M = {}

---@param tbl table
---@return FylerUiLine[]
local function TREE_STRUCTURE(tbl)
  local lines = {}
  for _, item in ipairs(tbl) do
    table.insert(
      lines,
      Line.new {
        Word.new(item.name, item.type == "directory" and "FylerBlue" or ""),
      }
    )
  end

  return lines
end

function M.FileTree(tbl)
  return {
    unpack(TREE_STRUCTURE(tbl)),
  }
end

return M

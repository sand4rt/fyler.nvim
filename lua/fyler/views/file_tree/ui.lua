local components = require("fyler.lib.ui.components")

local Line = components.Line
local Word = components.Word

local M = {}

---@param type string
---@param name string
function M.get_icon(type, name)
  local has_icons, minicons = pcall(require, "mini.icons")
  if not has_icons then
    return nil, nil
  end

  local status, icon, hl = pcall(minicons.get, type, name)
  if not status then
    return " ", ""
  end

  return icon, hl
end

---@param tbl table
---@return FylerUiLine[]
local function TREE_STRUCTURE(tbl)
  if not tbl then
    return {}
  end

  local lines = {}
  for _, item in ipairs(tbl) do
    local icon, hl = M.get_icon(item.type, item.name)
    if icon and hl then
      table.insert(
        lines,
        Line.new {
          Word.new(icon, hl),
          Word.new(string.format(" %s", item.name), item.type == "directory" and "FylerBlue" or ""),
          Word.new(string.format(" /%d", item.key)),
        }
      )
    else
      table.insert(
        lines,
        Line.new {
          Word.new(item.name, item.type == "directory" and "FylerBlue" or ""),
          Word.new(string.format(" /%d", item.key)),
        }
      )
    end
  end

  return lines
end

function M.FileTree(tbl)
  return {
    unpack(TREE_STRUCTURE(tbl)),
  }
end

return M

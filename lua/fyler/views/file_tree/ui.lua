local components = require("fyler.lib.ui.components")

local Line = components.Line
local Word = components.Word

local M = {}

---@param type string
---@param name string
function M.get_icon(type, name)
  local has_icons, minicons = pcall(require, "mini.icons")
  if not has_icons then
    return "", ""
  end

  local status, icon, hl = pcall(minicons.get, type, name)
  if not status then
    return "", ""
  end

  return icon, hl
end

local function get_sorted(tbl)
  table.sort(tbl, function(a, b)
    if a.type == "directory" and b.type == "file" then
      return true
    elseif a.type == "file" and b.type == "directory" then
      return false
    else
      return a.name < b.name
    end
  end)

  return tbl
end

---@param tbl table
---@return FylerUiLine[]
local function TREE_STRUCTURE(tbl, depth)
  depth = depth or 0

  if not tbl then
    return {}
  end

  local lines = {}
  for _, item in ipairs(get_sorted(tbl)) do
    local icon, hl = M.get_icon(item.type, item.name)
    table.insert(
      lines,
      Line.new {
        Word.new(string.rep(" ", depth * 2)),
        Word.new(icon, item.type == "directory" and "FylerBlue" or hl),
        Word.new(string.format(" %s", item.name), item.type == "directory" and "FylerBlue" or ""),
        Word.new(string.format(" /%d", item.key)),
      }
    )

    if item.children then
      for _, line in ipairs(TREE_STRUCTURE(item.children, depth + 1)) do
        table.insert(lines, line)
      end
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

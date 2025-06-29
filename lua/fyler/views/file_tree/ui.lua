local components = require("fyler.lib.ui.components")

local Line = components.Line
local Word = components.Word
local Mark = components.Mark

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

local BrokenLinkIcon = M.get_icon("default", "default")

local function get_sorted(tbl)
  table.sort(tbl, function(a, b)
    if a:is_directory() and not b:is_directory() then
      return true
    elseif not a:is_directory() and b:is_directory() then
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
    local icon, hl

    if item.type == "directory" then
      icon = M.get_icon(item.type, item.name)
      hl = "FylerBlue"
    elseif item.type == "link" and item.links_to.type == nil then
      -- This is a broken link
      icon = BrokenLinkIcon
      hl = "FylerRed"
    elseif item.type == "link" then
      icon = M.get_icon(item.links_to.type, item.name)
      hl = "FylerGreen"
    else
      icon, hl = M.get_icon(item.type, item.name)
    end

    table.insert(
      lines,
      Line {
        words = {
          Word(string.rep(" ", depth * 2)),
          Word(icon, item.type == "directory" and "FylerBlue" or hl),
          Word(string.format(" /%s", item.key)),
          Word(string.format(" %s", item.name), item.type == "directory" and "FylerBlue" or ""),
        },
        marks = item.type == "link" and {
          Mark("--> " .. item.links_to.path, "FylerYellow", item.key),
        } or {},
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
  return TREE_STRUCTURE(tbl)
end

return M

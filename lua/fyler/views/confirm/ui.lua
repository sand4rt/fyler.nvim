local components = require("fyler.lib.ui.components")

local Line = components.Line

local M = {}

---@param tbl table
function M.Confirm(tbl)
  if not tbl then return {} end

  local lines = {}
  for _, line in ipairs(tbl or {}) do
    table.insert(lines, Line.new { words = line })
  end

  return lines
end

return M

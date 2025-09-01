---@class MiniIconsIntegration
local M = {}

function M.get(type, name)
  local ok, miniicons = pcall(require, "mini.icons")
  assert(ok, "mini.icons are not installed or not loaded")

  return miniicons.get(type, name)
end

return M

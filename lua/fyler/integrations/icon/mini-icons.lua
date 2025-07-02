local M = {}

---@param type string
---@param name string
---@return string?, string?
function M.get_icon(type, name)
  local success, miniicons = pcall(require, "mini.icons")
  if not success then
    return nil, nil
  end

  return miniicons.get(type, name)
end

return M

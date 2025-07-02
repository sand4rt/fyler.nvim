local M = {}

---@param type string
---@param name string
---@return string?, string?
function M.get_icon(type, name)
  local success, devicons = pcall(require, "nvim-web-devicons")
  if not success then
    return nil, nil
  end

  local icon, hl = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"))
  icon = (type == "directory" and "" or (icon or ""))
  hl = hl or (type == "directory" and "Fylerblue" or "FylerWhite")
  return icon, hl
end

return M

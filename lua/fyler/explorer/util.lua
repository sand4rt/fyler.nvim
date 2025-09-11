local M = {}

---@param str string
---@return integer|nil
function M.parse_ref_id(str) return tonumber(str:match "/(%d+)") end

---@param str string
---@return integer
function M.parse_indent_level(str) return #(str:match("^(%s*)" or "")) end

---@param str string
---@return string
function M.parse_name(str)
  if M.parse_ref_id(str) then
    return str:match "/%d+ (.*)$"
  else
    return str:gsub("^%s*", ""):match ".*"
  end
end

return M

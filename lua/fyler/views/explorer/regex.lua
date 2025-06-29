local M = {}

---@param str string
---@return string
function M.match_meta(str)
  assert(str, "str is required")
  return str:match(" /(%d%d%d%d%d)")
end

---@param str string
---@return string
function M.match_name(str)
  assert(str, "str is required")
  return str:gsub(".*/%d%d%d%d%d ", ""):match(".*")
end

---@param str string
---@return string
function M.match_indent(str)
  assert(str, "str is required")
  return str:match("^(%s*)") or ""
end

return M

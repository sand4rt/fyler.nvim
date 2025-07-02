local M = {}

---@param str string
---@return string
function M.match_meta(str)
  assert(str, "str is required")
  return str:match(" /(%d%d%d%d%d)")
end

---@param str string
---@return string
function M.match_indent(str)
  assert(str, "str is required")
  return str:match("^(%s*)")
end

---@param str string
---@return string
function M.match_name(str)
  assert(str, "str is required")
  if str:match("/%d%d%d%d%d") then
    return str:match("/%d%d%d%d%d (.*)$")
  else
    return str:gsub("^%s*", ""):match(".*")
  end
end

return M

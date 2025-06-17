local M = {}

---@param str string
---@return string
local function trim(str)
  return str:gsub("^%s*", ""):gsub("%s*$", ""):match(".*")
end

---@param str string
---@return string
local function rmicon(str)
  return str:gsub("[\238\160\128-\238\163\191\243\176\128\128-\243\191\191\189]", ""):match(".*")
end

---@param str string
---@return string
local function rmkey(str)
  return str:gsub("/%d+$", ""):match(".*")
end

---@param str string
---@return integer?
function M.getkey(str)
  assert(str, "str is required")
  return tonumber((trim(str)):match("/(%d+)$"))
end

---@param str string
---@return string
function M.getname(str)
  assert(str, "str is required")
  return trim(rmicon(rmkey(trim(str))))
end

---@param str string
---@return string
function M.getindent(str)
  assert(str, "str is required")
  return str:match("(^%s*)")
end

return M

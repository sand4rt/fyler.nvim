local M = {}

local count = 0
local store = {}

---@param key integer
function M.get(key)
  return store[key]
end

---@param tbl table
---@return integer
function M.set(tbl)
  count = count + 1
  store[count] = tbl
  return count
end

return M

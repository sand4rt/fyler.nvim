local M = {}

local cache_table = {}

---@param entry_key string
---@param val any
function M.set_entry(entry_key, val)
  cache_table[entry_key] = val
end

---@param entry_key string
---@return any
function M.get_entry(entry_key)
  return vim.deepcopy(cache_table[entry_key])
end

return M

local M = {}

local count = 0
local store = {}
local Entry = {}
Entry.__index = Entry

---@return boolean
function Entry:is_dir()
  if self.type == "directory" then
    return true
  elseif self.type == "link" and self.link_type == "directory" then
    return true
  else
    return false
  end
end

---@return string
function Entry:get_path() return self.type == "link" and self.link_path or self.path end

---@param key string
function M.get_entry(key) return setmetatable(vim.deepcopy(store[key]), Entry) end

---@param tbl table
---@return string
function M.set_entry(tbl)
  count = count + 1
  local id = string.format("%05d", count)
  store[id] = tbl
  return id
end

function M.debug()
  for k, v in pairs(store) do
    print(k, vim.inspect(v))
  end
end

return M

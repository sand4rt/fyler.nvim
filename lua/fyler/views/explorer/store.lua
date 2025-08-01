local M = {}

local count = 0
local store = {}

local Metadata = {}
Metadata.__index = Metadata

function Metadata:is_directory()
  return self.type == "directory" or (self.type == "link" and self.link_type == "directory")
end

function Metadata:resolved_path() return self.type == "link" and self.link_path or self.path end

---@param key string
function M.get(key) return setmetatable(vim.deepcopy(store[key]), Metadata) end

---@param tbl table
---@return string
function M.set(tbl)
  count = count + 1
  local meta = string.format("%05d", count)
  store[meta] = tbl
  return meta
end

function M.debug()
  for k, v in pairs(store) do
    print(k, vim.inspect(v))
  end
end

return M

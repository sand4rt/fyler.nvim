local M = {}

local count = 0
local store = {}

local Entry = {}
Entry.__index = Entry

function Entry:is_dir() return self.type == "directory" or (self.type == "link" and self.link_type == "directory") end

function Entry:get_path() return self.type == "link" and self.link_path or self.path end

---@param key string
function M.get(key) return setmetatable(vim.deepcopy(store[key]), Entry) end

---@param tbl table
---@return string
function M.set(tbl)
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

local M = {}
local FylerHashTable = {}

function M.reset()
  FylerHashTable = {}
end

function M.set(key_path, value)
  local path = FylerHashTable
  for i = 1, #key_path - 1 do
    if not path[key_path[i]] then
      path[key_path[i]] = {}
    end

    path = path[key_path[i]]
  end

  path[key_path[#key_path]] = value
end

---@param key_path string[]
---@return any
function M.get(key_path)
  local path = FylerHashTable
  for i = 1, #key_path do
    if not path[key_path[i]] then
      return nil
    end

    path = path[key_path[i]]
  end

  return path
end

function M.debug()
  print(vim.inspect(FylerHashTable))
end

return M

local M = {}

local uv = vim.uv or vim.loop
local fn = vim.fn

---@return string
function M.getcwd()
  return uv.cwd() or fn.getcwd(0)
end

---@param a string
---@param b string
function M.joinpath(a, b)
  assert(a and b, "path is required")

  if vim.endswith(a, "/") then
    a = a:sub(1, -2)
  end

  if vim.startswith(b, "/") then
    b = b:sub(2)
  end

  return ("%s/%s"):format(a, b)
end

---@param path string
---@return string
function M.toabspath(path)
  return M.joinpath(M.getcwd(), path)
end

---@param path string
---@param callback fun(err?: string)
function M.touch(path, callback)
  uv.fs_stat(path, function(_, stats)
    if stats then
      callback("Item already exists")
    else
      uv.fs_open(path, "a", 420, function(o_err, fd)
        if o_err then
          callback(o_err)
        else
          assert(fd, "fd is a nil")
          uv.fs_close(fd, callback)
        end
      end)
    end
  end)
end

---@param path string
---@return table, string?
function M.listdir(path)
  assert(path, "path is required")

  local items = {}
  local fs, err = uv.fs_scandir(path)
  if not fs then
    return {}, err
  end

  while true do
    local name, type = uv.fs_scandir_next(fs)
    if not name then
      break
    end

    table.insert(items, {
      name = name,
      type = type,
      path = M.joinpath(path, name),
    })
  end

  return items, nil
end

return M

local M = {}
local uv = vim.uv or vim.loop

function M.getcwd()
  return uv.cwd() or vim.fn.getcwd(0)
end

---@param path string
function M.toabsolute(path)
  if not path then
    return
  end

  if vim.startswith(path, '.') then
    return vim.fs.joinpath(M.getcwd(), path:sub(2))
  end

  if not vim.startswith(path, '/') then
    return vim.fs.joinpath(M.getcwd(), path)
  end

  return path
end

return M

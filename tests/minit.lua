local M = dofile "bin/setup_deps.lua"

---@param t table
---@return table
local function map(t)
  return vim
    .iter(t)
    :map(function(dep)
      return dep:match "/(.*)$"
    end)
    :totable()
end

for _, dep in ipairs(map(M.dependencies)) do
  local path = vim.fs.joinpath(M.get_dir(), "repo", dep)
  if vim.fn.isdirectory(path) == 1 then
    vim.opt.runtimepath:prepend(path)
  end
end

vim.opt.runtimepath:prepend "."

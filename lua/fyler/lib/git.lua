local a = require("fyler.lib.async")
local fs = require("fyler.lib.fs")

local M = {}

---@param cb fun(result: boolean)
local is_git_repo = a.async(function(cb)
  local out = a.await(vim.system, { "git", "rev-parse", "--is-inside-work-tree" }, nil) ---@type vim.SystemCompleted
  return cb(string.match(out.stdout, "^(.*)\n$") == "true")
end)

---@param cb fun(status?: string)
local git_status = a.async(function(cb)
  if not a.await(is_git_repo) then
    return cb(nil)
  end

  local out = a.await(vim.system, { "git", "status", "--porcelain", "-z" }, nil) ---@type vim.SystemCompleted
  if not out.stdout then
    return cb(nil)
  end

  return cb(out.stdout)
end)

---@param cb fun(path?: string)
local git_toplevel = a.async(function(cb)
  local out = a.await(vim.system, { "git", "rev-parse", "--show-toplevel" }, nil) ---@type vim.SystemCompleted
  if not out.stdout then
    return cb(nil)
  end

  return cb(string.match(out.stdout, "^(.*)\n$"))
end)

---@param cb fun(status_map?: table)
M.status_map = a.async(function(cb)
  local status_str = a.await(git_status)
  if not status_str then
    return cb(nil)
  end

  local statuses = vim
    .iter(vim.split(status_str, "\0"))
    :filter(function(status)
      if status == "" then
        return false
      end

      return true
    end)
    :totable()

  local toplevel = a.await(git_toplevel)
  if not toplevel then
    return cb(nil)
  end

  local status_map = {}
  for _, status in ipairs(statuses) do
    local symbol, path = (function()
      if string.match(status, "^.*%s.*$") then
        return string.match(status, "^(.*)%s(.*)$")
      else
        return nil, status
      end
    end)()

    status_map[fs.joinpath(toplevel, fs.normalize(path))] = symbol
  end

  return cb(status_map)
end)

return M

local a = require("fyler.lib.async")
local fs = require("fyler.lib.fs")
local util = require("fyler.lib.util")

local M = {}

local async = a.async
local await = a.await

---@param cb fun(result: boolean)
local is_git_repo = async(function(cb)
  local out = await(vim.system, { "git", "rev-parse", "--is-inside-work-tree" }, nil) ---@type vim.SystemCompleted
  return cb(string.match(out.stdout, "^(.*)\n$") == "true")
end)

---@param cb fun(status: string|nil)
local git_status = async(function(cb)
  if not await(is_git_repo) then return cb(nil) end

  local out = await(vim.system, { "git", "status", "--porcelain", "-z" }, nil) ---@type vim.SystemCompleted
  if not out.stdout then return cb(nil) end

  return cb(out.stdout)
end)

---@param cb fun(path: string|nil)
local git_toplevel = async(function(cb)
  local out = await(vim.system, { "git", "rev-parse", "--show-toplevel" }, nil) ---@type vim.SystemCompleted
  if not out.stdout then return cb(nil) end

  return cb(string.match(out.stdout, "^(.*)\n$"))
end)

---@param cb fun(status_map: table|nil)
M.status_map = async(function(cb)
  local status_str = await(git_status)
  if not status_str then return cb(nil) end

  local statuses = util.filter_bl(vim.split(status_str, "\0"))

  local toplevel = await(git_toplevel)
  if not toplevel then return cb(nil) end

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

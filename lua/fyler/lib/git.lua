local a = require("fyler.lib.async")
local fs = require("fyler.lib.fs")
local util = require("fyler.lib.util")

local M = {}

local system = a.wrap(function(cmd, cb) cb(vim.system(cmd, { text = true }):wait()) end)

---@param cb fun(result: boolean)
local is_git_repo = a.wrap(function(cb)
  local out = system { "git", "rev-parse", "--is-inside-work-tree" }
  return cb(string.match(out.stdout, "^(.*)\n$") == "true")
end)

---@param cb fun(status: string|nil)
local git_status = a.wrap(function(cb)
  if not is_git_repo() then return cb(nil) end

  local out = system { "git", "status", "--porcelain", "-z" }
  if not out.stdout then return cb(nil) end

  return cb(out.stdout)
end)

---@param cb fun(path: string|nil)
local git_toplevel = a.wrap(function(cb)
  local out = system { "git", "rev-parse", "--show-toplevel" }
  if not out.stdout then return cb(nil) end

  return cb(string.match(out.stdout, "^(.*)\n$"))
end)

---@param cb fun(status_map: table|nil)
M.status_map = a.wrap(function(cb)
  local status_str = git_status()
  if not status_str then return cb(nil) end

  local statuses = util.filter_bl(vim.split(status_str, "\0"))

  local toplevel = git_toplevel()
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

local fs = require "fyler.lib.fs"
local util = require "fyler.lib.util"

local M = {}

local system = function(cmd) return vim.system(cmd, { text = true }):wait() end

local function is_git_repo()
  local out = system { "git", "rev-parse", "--is-inside-work-tree" }
  return string.match(out.stdout, "^(.*)\n$") == "true"
end

local function git_status()
  if not is_git_repo() then return nil end

  local out = system { "git", "status", "--porcelain", "-z" }
  if not out.stdout then return nil end

  return out.stdout
end

local function git_toplevel()
  local out = system { "git", "rev-parse", "--show-toplevel" }
  if not out.stdout then return nil end

  return string.match(out.stdout, "^(.*)\n$")
end

function M.status_map()
  local status_str = git_status()
  if not status_str then return nil end

  local statuses = util.filter_bl(vim.split(status_str, "\0"))

  local toplevel = git_toplevel()
  if not toplevel then return nil end

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

  return status_map
end

return M

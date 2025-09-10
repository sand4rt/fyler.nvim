local config = require "fyler.config"
local fs = require "fyler.lib.fs"
local util = require "fyler.lib.util"
local M = {}

local git_status_map = {
  ["??"] = "Untracked",
  ["A "] = "Added",
  ["AM"] = "Added",
  [" M"] = "Modified",
  ["MM"] = "Modified",
  ["M "] = "Modified",
  [" D"] = "Deleted",
  ["D "] = "Deleted",
  ["MD"] = "Deleted",
  ["AD"] = "Deleted",
  ["R "] = "Renamed",
  ["RM"] = "Renamed",
  ["RD"] = "Renamed",
  ["C "] = "Copied",
  ["CM"] = "Copied",
  ["CD"] = "Copied",
  ["DD"] = "Conflict",
  ["AU"] = "Conflict",
  ["UD"] = "Conflict",
  ["UA"] = "Conflict",
  ["DU"] = "Conflict",
  ["AA"] = "Conflict",
  ["UU"] = "Conflict",
  ["!!"] = "Ignored",
}

local git_highlight_map = {
  Untracked = "FylerGitUntracked",
  Added = "FylerGitAdded",
  Modified = "FylerGitModified",
  Deleted = "FylerGitDeleted",
  Renamed = "FylerGitRenamed",
  Copied = "FylerGitCopied",
  Conflict = "FylerGitConflict",
  Ignored = "FylerGitIgnored",
}

local cached_status_map = {}

local function system(cmd) return vim.system(cmd, { text = true }):wait() end

local function worktree_root()
  local out = system { "git", "rev-parse", "--show-toplevel" }
  if not out.stdout then return end

  return string.match(out.stdout, "^(.*)\n$")
end

function M.inside_worktree() return system({ "git", "rev-parse", "--is-inside-work-tree" }).code == 0 end

function M.refresh()
  if not M.inside_worktree() then return end

  local dir = worktree_root()
  if not dir then return end

  local out = system { "git", "status", "--porcelain", "-z" }
  if not out.stdout then return end

  local status_list = util.filter_bl(vim.split(out.stdout, "\0"))
  local status_map = {}

  for _, status in ipairs(status_list) do
    local symbol = string.sub(status, 1, 2)
    local path = string.sub(status, 4)
    status_map[fs.joinpath(dir, fs.normalize(path))] = git_status_map[symbol]
  end

  cached_status_map = status_map
end

---@param path string
---@return string|nil, string|nil, string|nil
function M.status(path)
  local normalized_path = fs.normalize(path)
  local status_info = cached_status_map[normalized_path]
  if not status_info then return end

  return config.values.git_status.symbols[status_info], git_highlight_map[status_info]
end

return M

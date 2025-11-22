local Path = require "fyler.lib.path"
local fs = require "fyler.lib.fs"

local M = {}

function M.get_trash_dir(callback)
  vim.schedule(function()
    callback(Path.new(vim.uv.os_homedir() or vim.fn.expand "$HOME"):join(".Trash"):normalize())
  end)
end

---@param basename string
function M.next_name(dir, basename)
  if not Path.new(dir):join(basename):exists() then
    return basename
  end

  local name, extension = vim.fn.fnamemodify(basename, ":r"), vim.fn.fnamemodify(basename, ":e")
  local counter = 1
  while true do
    local candidate = string.format("%s (%d).%s", name, counter, extension)
    if not Path.new(dir):join(candidate):exists() then
      return candidate
    end

    counter = counter + 1
  end
end

---@param path string
---@param callback function
function M.dump(path, callback)
  M.get_trash_dir(function(trash_dir)
    local path_to_trash = Path.new(path)
    local target_path = Path.new(trash_dir):join(M.next_name(trash_dir, path_to_trash:basename()))

    fs.mv(path_to_trash:normalize(), target_path:normalize(), function(err)
      callback(err)
    end)
  end)
end

return M

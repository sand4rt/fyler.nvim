local Path = require "fyler.lib.path"
local fs = require "fyler.lib.fs"

local M = {}

function M.get_trash_dir(callback)
  vim.schedule(function()
    local dir = Path.new(vim.F.if_nil(vim.env.XDG_DATA_HOME, vim.fs.joinpath(vim.fn.expand "$HOME", ".local", "share")))
      :join "Trash"
    callback(dir:join("files"):normalize(), dir:join("info"):normalize())
  end)
end

---@param dir string
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
  local path_to_trash = Path.new(path)
  M.get_trash_dir(function(files, info)
    fs.mkdir.p(files, function(err)
      if err then
        return callback(err)
      end

      fs.mkdir.p(info, function(err_info)
        if err_info then
          return callback(err_info)
        end

        local target_name = M.next_name(files, path_to_trash:basename())
        local target_path = Path.new(files):join(target_name)
        local trash_info = table.concat({
          "[Trash Info]",
          string.format("Path=%s", path_to_trash:normalize()),
          string.format("DeletionDate=%s", os.date "%Y-%m-%dT%H:%M:%S"),
        }, "\n")

        -- Writing meta data to "%.trashinfo"
        fs.write(Path.new(info):join(target_name .. ".trashinfo"):normalize(), trash_info, function(err_write)
          if err_write then
            return callback(err_write)
          end

          -- Move to trash directory
          fs.mv(path_to_trash:normalize(), target_path:normalize(), function(err_mv)
            callback(err_mv)
          end)
        end)
      end)
    end)
  end)
end

return M

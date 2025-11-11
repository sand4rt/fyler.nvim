local Path = require "fyler.lib.path"
local fs = require "fyler.lib.fs"

local M = {}

---@return string, string
function M.get_trash_dir()
  local dir = Path.new(vim.F.if_nil(vim.env.XDG_DATA_HOME, vim.fs.joinpath(vim.fn.expand "$HOME", ".local", "share")))
    :join "Trash"
  return dir:join("files"):normalize(), dir:join("info"):normalize()
end

---@param basename string
function M.next_name(basename)
  local dir = M.get_trash_dir()
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
function M.dump(path)
  local path_to_trash = Path.new(path)
  local files, info = M.get_trash_dir()

  fs.mkdir.p(files)
  fs.mkdir.p(info)

  local target_name = M.next_name(path_to_trash:basename())
  local target_path = Path.new(files):join(target_name)
  local trash_info = table.concat({
    "[Trash Info]",
    string.format("Path=%s", path_to_trash:normalize()),
    string.format("DeletionDate=%s", os.date "%Y-%m-%dT%H:%M:%S"),
  }, "\n")

  -- Writing meta data to "%.trashinfo"
  fs.write(Path.new(info):join(target_name .. ".trashinfo"):normalize(), trash_info)

  -- Move to trash directory
  fs.mv(path_to_trash:normalize(), target_path:normalize())
end

return M

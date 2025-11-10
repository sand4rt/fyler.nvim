local Path = require "fyler.lib.path"
local config = require "fyler.config"

local M = {
  _instances = {}, ---@type table<string, uv.uv_fs_event_t>
}

---@param path string
---@param callback function
function M.register(path, callback)
  if not config.values.views.finder.watcher.enabled then
    return
  end

  local _path = Path.new(path)
  if not _path:exists() then
    return
  end

  M._instances[_path:absolute()] = assert(vim.uv.new_fs_event())
  M._instances[_path:absolute()]:start(_path:absolute(), {}, callback)
end

---@param path string
function M.unregister(path)
  if not config.values.views.finder.watcher.enabled then
    return
  end

  local _path = Path.new(path)
  local fs_event = M._instances[_path:absolute()]
  if not fs_event then
    return
  end

  fs_event:stop()
end

return M

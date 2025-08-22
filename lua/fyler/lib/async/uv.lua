local a = require("fyler.lib.async")

local M = {}

local uv = vim.uv or vim.loop

do
  -- stylua: ignore start
  local async_map = {
    fs_close    = uv.fs_close,
    fs_copyfile = uv.fs_copyfile,
    fs_mkdir    = uv.fs_mkdir,
    fs_open     = uv.fs_open,
    fs_readdir  = uv.fs_readdir,
    fs_readlink = uv.fs_readlink,
    fs_rename   = uv.fs_rename,
    fs_rmdir    = uv.fs_rmdir,
    fs_stat     = uv.fs_stat,
    fs_unlink   = uv.fs_unlink,

    -- Rearrange function parameters for "async.wrap" compatibility
    fs_opendir  = function(path, entries, next) vim.uv.fs_opendir(path, next, entries) end,
  }
  -- stylua: ignore start

  for name, fn in pairs(async_map) do
    M[name] = a.wrap(fn)
  end
end

return M

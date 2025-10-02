local M = {}

local did_setup = false

---@param opts FylerSetupOptions
function M.setup(opts)
  if vim.fn.has "nvim-0.11" ~= 1 then
    return vim.notify "Fyler requires at least NVIM 0.11"
  end

  if did_setup then
    return
  end

  -- Overwrite default configuration before setuping other components
  local config = require "fyler.config"
  config.setup(opts)

  require("fyler.autocmds").setup(config)
  require("fyler.hooks").setup(config)
  require("fyler.lib.hls").setup()

  did_setup = true

  local explorer = require "fyler.explorer"
  local fs = require "fyler.lib.fs"
  local util = require "fyler.lib.util"
  local e_util = require "fyler.explorer.util"

  ---@return Explorer|nil
  M.current = function()
    return explorer.current()
  end

  ---@param dir string
  ---@return Explorer
  local function get_or_create_instance(dir)
    return explorer.instance(dir) or explorer.new(dir, config)
  end

  ---@param e_opts table|nil
  ---@return string dir, string kind
  local function get_dir_and_kind(e_opts)
    e_opts = e_opts or {}
    local current = M.current()
    local dir = e_opts.dir or (current and current:getcwd()) or fs.cwd()
    local kind = e_opts.kind or (current and current.win and current.win.kind) or config.values.win.kind
    return dir, kind
  end

  ---@param dir string|nil
  ---@return Explorer
  M.instance = function(dir)
    assert(dir, "cannot locate instance without dir")
    return get_or_create_instance(dir)
  end

  M.open = vim.schedule_wrap(function(e_opts)
    local dir, kind = get_dir_and_kind(e_opts)

    local current = M.current()
    if current and not current:eq_with(dir, kind) then
      current:close()
    end

    get_or_create_instance(dir):open(dir, kind)
  end)

  M.close = function()
    local current = M.current()
    if current then
      current:close()
    end
  end

  M.toggle = function(e_opts)
    local dir, kind = get_dir_and_kind(e_opts)
    local current = M.current()

    if current then
      if e_util.is_protocol_path(dir) or current:eq_with(dir, kind) then
        if current:is_visible() then
          current:close()
        else
          current:open(dir, kind)
        end
      else
        current:close()
        get_or_create_instance(dir):open(dir, kind)
      end
    else
      get_or_create_instance(dir):open(dir, kind)
    end
  end

  ---@param name string|nil
  M.track_buffer = function(name)
    local current = M.current()
    if not current then
      return
    end

    local buffer_path = name or vim.fn.expand "%:p"
    util.debounce("focus_buffer", 10, function()
      current:track_buffer(buffer_path)
    end)
  end
end

return M

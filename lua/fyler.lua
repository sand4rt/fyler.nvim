local M = {}

-- A local variable which prevents "Fyler.nvim" to re-setup
local did_setup = false

-- Setup function setup various plugin components, Like config, autocommands, hooks and highlights.
-- It also exposes some "Fyler.nvim" APIS
---@param options FylerConfig
function M.setup(options)
  if vim.fn.has "nvim-0.11" ~= 1 then return vim.notify "Fyler requires at least NVIM 0.11" end

  -- Early return if already been setuped
  if did_setup then return end
  -- Overwrite default configuration before setuping other components
  local config = require "fyler.config"
  config.setup(options)

  require("fyler.autocmds").setup(config)
  require("fyler.hooks").setup(config)
  require("fyler.lib.hls").setup()

  -- Mark setup as completed
  did_setup = true

  local explorer = require "fyler.explorer"
  local fs = require "fyler.lib.fs"
  local log = require "fyler.log"

  -- "Fyler.nvim" API to launch explorer with defined options
  M.open = vim.schedule_wrap(function(opts)
    local dir = opts.dir or fs.cwd()
    local kind = opts.kind or config.values.win.kind
    local instance = explorer.instance(dir)
    local current = explorer.current()

    if current and current.dir ~= dir then current:_action "n_close"() end

    if instance then
      instance:open(dir, kind)
    else
      explorer.new(dir, config):open(dir, kind)
    end
  end)

  -- "Fyler.nvim" API to track (given or current) buffer
  ---@param file string|nil
  M.track_buffer = function(file)
    local current = explorer.current()
    if not current then
      log.error "No existing explorer"
      return
    end

    current:_action "try_focus_buffer" { file = file or vim.fn.expand "%:p" }
  end
end

return M

local FSItem = require("fyler.views.explorer.struct")
local Win = require("fyler.lib.win")
local a = require("fyler.lib.async")
local config = require("fyler.config")
local fs = require("fyler.lib.fs")
local store = require("fyler.views.explorer.store")

local fn = vim.fn
local api = vim.api

---@class FylerExplorerView
---@field cwd     string      - Directory path which act as a root
---@field fs_root FylerFSItem - Root |FylerFSItem| instance
---@field win     FylerWin    - Window instance
local ExplorerView = {}
ExplorerView.__index = ExplorerView

function ExplorerView.new(opts)
  local fs_root = FSItem(store.set {
    name = fn.fnamemodify(opts.cwd, ":t"),
    type = "directory",
    path = opts.cwd,
  })

  fs_root:toggle()

  local instance = {
    cwd = opts.cwd,
    fs_root = fs_root,
    kind = opts.kind,
  }

  setmetatable(instance, ExplorerView)

  return instance
end

ExplorerView.open = a.async(function(self, opts)
  local mappings = config.get_reverse_mappings("explorer")
  local win = config.get_view("explorer", opts.kind).win

  -- stylua: ignore start
  self.win = Win {
    border   = win.border,
    buf_opts = win.buf_opts,
    bufname  = string.format("fyler://%s", self.cwd),
    enter    = opts.enter,
    height   = win.height,
    kind     = opts.kind or win.kind,
    name     = "explorer",
    width    = win.width,
    win_opts = win.win_opts,
    mappings = {
      [mappings["Select"]]    = self:_action("n_select"),
      [mappings["CloseView"]] = self:_action("n_close_view"),
    },
    autocmds = {
      ["BufReadCmd"]   = self:_action("refreshview"),
      ["BufWriteCmd"]  = self:_action("synchronize"),
      ["CursorMoved"]  = self:_action("constrain_cursor"),
      ["CursorMovedI"] = self:_action("constrain_cursor"),
      ["WinClosed"]    = self:_action("n_close_view"),
    },
    user_autocmds = {
      ["RefreshView"] = self:_action("refreshview"),
      ["Synchronize"] = self:_action("synchronize"),
    },
    render = self:_action("refreshview"),
  }
  -- stylua: ignore end

  require("fyler.cache").set_entry("recent_win", api.nvim_get_current_win())

  self.win:show()
end)

---@param ... any
function ExplorerView:_action(name, ...)
  local action = require("fyler.views.explorer.actions")[name]

  assert(action, string.format("%s action is not available", name))

  return action(self, ...)
end

local M = {
  instance = nil, ---@type FylerExplorerView
}

---@param opts { cwd?: string, kind?: FylerWinKind }
---@return FylerExplorerView
function M.get_instance(opts)
  if (not M.instance) or (M.instance.cwd ~= opts.cwd) then
    M.instance = ExplorerView.new {
      cwd = opts.cwd,
      kind = opts.kind,
    }
  end

  return M.instance
end

---@param opts? { enter?: boolean, cwd?: string, kind?: FylerWinKind }
function M.open(opts)
  opts = opts or {}
  opts.enter = opts.enter == nil and true or opts.enter
  opts.cwd = opts.cwd or fs.getcwd()
  opts.kind = opts.kind or config.get_view("explorer").kind

  if M.instance and fn.winbufnr(M.instance.win.winid) == M.instance.win.bufnr then
    M.instance.win:hide()
  end

  M.get_instance(opts):open(opts)
end

return M

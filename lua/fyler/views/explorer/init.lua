local FSItem = require("fyler.views.explorer.struct")
local Win = require("fyler.lib.win")
local algos = require("fyler.views.explorer.algos")
local config = require("fyler.config")
local fs = require("fyler.lib.fs")
local store = require("fyler.views.explorer.store")
local ui = require("fyler.views.explorer.ui")

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

function ExplorerView:open(opts)
  local mappings = config.get_reverse_mappings("explorer")

  self.fs_root:update()

  self.win = Win {
    bufname = string.format("fyler://%s", self.cwd),
    bufopts = {
      syntax = "fyler",
      filetype = "fyler",
      buftype = "acwrite",
    },
    enter = true,
    kind = opts.kind,
    name = "explorer",
    winopts = {
      concealcursor = "nvic",
      conceallevel = 3,
      cursorline = true,
      number = true,
      relativenumber = true,
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
      wrap = false,
    },
    -- stylua: ignore start
    mappings = {
      n = {
        [mappings["Select"]]          = self:_action("n_select"),
        [mappings["SelectRecursive"]] = self:_action("n_select_recursive"),
        [mappings["CloseView"]]       = self:_action("n_close_view"),
      },
    },
    autocmds = {
      ["BufReadCmd"]   = self:_action("n_refreshview"),
      ["BufWriteCmd"]  = self:_action("n_synchronize"),
      ["CursorMoved"]  = self:_action("constrain_cursor"),
      ["CursorMovedI"] = self:_action("constrain_cursor"),
      ["WinClosed"]    = self:_action("n_close_view"),
    },
    user_autocmds = {
      ["RefreshView"] = self:_action("n_refreshview"),
      ["Synchronize"] = self:_action("n_synchronize"),
    },
    -- stylua: ignore end
    render = function()
      return {
        lines = ui.Explorer(algos.tree_table_from_node(self).children),
      }
    end,
  }

  require("fyler.cache").set_entry("recent_win", api.nvim_get_current_win())

  self.win:show()

  self:_action("try_focus_buffer")()
end

function ExplorerView:close()
  if self.win then
    self.win:hide()
  end
end

---@param name string
function ExplorerView:_action(name)
  local action = require("fyler.views.explorer.actions")[name]

  assert(action, string.format("%s action is not available", name))

  return action(self)
end

local M = {
  instances = {},
  root_dir = nil,
}

---@param opts { cwd?: string, kind?: FylerWinKind }
---@return FylerExplorerView
function M.get_instance(opts)
  if M.instances[opts.cwd] then
    return M.instances[opts.cwd]
  end

  M.root_dir = opts.cwd
  M.instances[opts.cwd] = ExplorerView.new {
    cwd = opts.cwd,
    kind = opts.kind,
  }

  return M.instances[opts.cwd]
end

---@param opts { cwd?: string, kind?: FylerWinKind }
function M.open(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or fs.getcwd()
  opts.kind = opts.kind or config.get_view("explorer").kind

  local cur_instance = M.get_instance(opts)
  cur_instance:close()
  cur_instance:open(opts)
end

return M

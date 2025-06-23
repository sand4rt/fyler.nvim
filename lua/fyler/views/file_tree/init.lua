local TreeNode = require("fyler.views.file_tree.struct")
local Win = require("fyler.lib.win")
local algos = require("fyler.views.file_tree.algos")
local config = require("fyler.config")
local fs = require("fyler.lib.fs")
local store = require("fyler.views.file_tree.store")
local ui = require("fyler.views.file_tree.ui")

local fn = vim.fn
local api = vim.api

---@class FylerTreeView
---@field cwd       string
---@field win       FylerWin
---@field tree_node FylerTreeNode
local FileTreeView = {}
FileTreeView.__index = FileTreeView

---@class FylerTreeViewOpenOpts
---@field cwd           string
---@field focused_path? string
---@field kind?         FylerWinKind

---@param opts FylerTreeViewOpenOpts
function FileTreeView.new(opts)
  local tree_node = TreeNode(store.set {
    name = fn.fnamemodify(opts.cwd, ":t"),
    type = "directory",
    path = opts.cwd,
  })

  tree_node:toggle()

  local instance = {
    cwd = opts.cwd,
    kind = opts.kind,
    tree_node = tree_node,
  }

  setmetatable(instance, FileTreeView)

  return instance
end

---@param opts FylerTreeViewOpenOpts
function FileTreeView:open(opts)
  local mappings = config.get_reverse_mappings("file_tree")

  self.tree_node:update()

  local rel = vim.fs.relpath(opts.cwd, opts.focused_path or "")
  local parts = {}
  if rel then
    parts = vim.split(rel, "/")
  end

  local focused_node = self.tree_node
  for _, part in pairs(parts) do
    local child = vim.iter(focused_node.children):find(function(child)
      return store.get(child.data).name == part
    end)
    if not child then
      break
    end
    child.open = true
    child:update()
    focused_node = child
  end

  self.win = Win {
    enter = true,
    name = "file_tree",
    bufname = string.format("fyler://%s", self.cwd),
    kind = opts.kind,
    bufopts = {
      syntax = "fyler",
      filetype = "fyler",
      buftype = "acwrite",
    },
    winopts = {
      wrap = false,
      number = true,
      relativenumber = true,
      conceallevel = 3,
      concealcursor = "nvic",
      cursorline = true,
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
      ["WinClosed"]   = self:_action("n_close_view"),
      ["BufReadCmd"]  = self:_action("n_refreshview"),
      ["BufWriteCmd"] = self:_action("n_synchronize"),
      ["CursorMoved"] = self:_action("constrain_cursor"),
      ["CursorMovedI"] = self:_action("constrain_cursor"),
    },
    user_autocmds = {
      ["RefreshView"] = self:_action("n_refreshview"),
      ["Synchronize"] = self:_action("n_synchronize"),
    },
    -- stylua: ignore end
    render = function()
      return ui.FileTree(algos.tree_table_from_node(self).children)
    end,
    on_open = function()
      vim.fn.search(string.format("/%s$", focused_node.data), "w")
      vim.cmd(":normal _")
    end,
  }

  require("fyler.cache").set_entry("recent_win", api.nvim_get_current_win())

  self.win:show()
end

function FileTreeView:close()
  self.win:hide()
end

---@param name string
function FileTreeView:_action(name)
  local action = require("fyler.views.file_tree.actions")[name]

  assert(action, string.format("%s action is not available", name))

  return action(self)
end

local M = {
  instance = {},
}

---@param opts { cwd?: string, kind?: FylerWinKind, focused_path?: string }
function M.open(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or fs.getcwd()
  opts.focused_path = opts.focused_path or api.nvim_buf_get_name(0)
  opts.kind = opts.kind or config.get_view("file_tree").kind

  if M.instance.close then
    M.instance:close()
  end

  if M.instance.cwd ~= opts.cwd then
    M.instance = FileTreeView.new {
      cwd = opts.cwd,
      kind = opts.kind,
    }
  end

  M.instance:open(opts)
end

return M

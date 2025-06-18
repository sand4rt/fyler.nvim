local TreeNode = require("fyler.views.file_tree.struct")
local Win = require("fyler.lib.win")
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
---@field cwd    string
---@field kind?  FylerWinKind

---@param opts FylerTreeViewOpenOpts
function FileTreeView.new(opts)
  local tree_node = TreeNode.new(store.set {
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

  self.win = Win.new {
    enter = true,
    name = "file_tree",
    kind = opts.kind,
    bufopts = {
      syntax = "fyler",
      filetype = "fyler",
    },
    winopts = {
      number = true,
      relativenumber = true,
      conceallevel = 3,
      concealcursor = "nvic",
    },
    -- stylua: ignore start
    mappings = {
      n = {
        [mappings["CloseView"]]  = self:_action("n_close_view"),
        [mappings["Select"]]     = self:_action("n_select"),
      },
    },
    -- stylua: ignore end
    autocmds = {
      ["WinClosed"] = self:_action("n_close_view"),
    },
    render = function()
      return ui.FileTree(self:update_tree():to_table().children)
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

---@return FylerTreeView
function FileTreeView:update_tree()
  ---@param tree_node FylerTreeNode
  local function dfs(tree_node)
    if not tree_node.open then
      return
    end

    local meta_data = store.get(tree_node.data)
    local items, err = fs.listdir(meta_data.path)
    if err then
      return
    end

    tree_node.children = vim
      .iter(tree_node.children)
      :filter(function(child) ---@param child FylerTreeNode
        return vim.iter(items):any(function(item)
          return item.path == store.get(child.data).path and item.type == store.get(child.data).type
        end)
      end)
      :totable()

    for _, item in ipairs(items) do
      if
        not vim.iter(tree_node.children):any(function(child) ---@param child FylerTreeNode
          return store.get(child.data).path == item.path and store.get(child.data).type == item.type
        end)
      then
        tree_node:add_child(tree_node.data, store.set(item))
      end
    end

    for _, child in ipairs(tree_node.children) do
      dfs(child)
    end
  end

  dfs(self.tree_node)

  return self
end

---@return table
function FileTreeView:to_table()
  ---@param tree_node FylerTreeNode
  local function get_tbl(tree_node)
    local sub_tbl = store.get(tree_node.data)
    sub_tbl.key = tree_node.data

    if not tree_node.open then
      return sub_tbl
    end

    sub_tbl.children = {}
    for _, child in ipairs(tree_node.children) do
      table.insert(sub_tbl.children, get_tbl(child))
    end

    table.sort(sub_tbl.children, function(a, b)
      if a.type == "directory" and b.type == "file" then
        return true
      elseif a.type == "file" and b.type == "directory" then
        return false
      else
        return a.name < b.name
      end
    end)

    return sub_tbl
  end

  return get_tbl(self.tree_node)
end

function FileTreeView:refresh()
  self.win.ui:render(ui.FileTree(self:update_tree():to_table().children))
end

local M = {
  instance = {},
}

---@param opts { cwd?: string, kind?: FylerWinKind }
function M.open(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or fs.getcwd()
  opts.kind = opts.kind or config.get_view("file_tree").kind

  if M.instance.cwd ~= opts.cwd then
    M.instance = FileTreeView.new {
      cwd = opts.cwd,
      kind = opts.kind,
    }
  end

  M.instance:open(opts)
end

return M

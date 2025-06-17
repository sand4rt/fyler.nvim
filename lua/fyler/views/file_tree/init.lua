local Tree = require("fyler.lib.structures.tree")
local Win = require("fyler.lib.win")
local fs = require("fyler.lib.fs")
local ui = require("fyler.views.file_tree.ui")

local M = {
  count = 0,
  store = {},
  instances = {}, ---@type FylerTreeView[]
}

local fn = vim.fn
local uv = vim.uv or vim.loop

local view_name = "tree_view"

---@class FylerTreeView
---@field cwd    string
---@field win    FylerWin
---@field tree   FylerTree
---@field config FylerConfig
local FileTreeView = {}
FileTreeView.__index = FileTreeView

local view_mt = {
  ---@param a FylerTreeView
  ---@param b FylerTreeView
  __lt = function(a, b)
    return a.cwd < b.cwd
  end,
  ---@param a FylerTreeView
  ---@param b FylerTreeView
  __eq = function(a, b)
    return a.cwd == b.cwd
  end,
}

local tree_mt = {
  ---@param a FylerTreeNode
  ---@param b FylerTreeNode
  __lt = function(a, b)
    local ad = a.data
    local bd = b.data

    if ad.type == "directory" and bd.type == "file" then
      return true
    elseif ad.type == "file" and bd.type == "directory" then
      return false
    else
      return ad.name < bd.name
    end
  end,
  ---@param a FylerTreeNode
  ---@param b FylerTreeNode
  __eq = function(a, b)
    local ad = a.data
    local bd = b.data

    return ad.name == bd.name and ad.type == bd.type and ad.path == bd.path
  end,
}

---@class FylerTreeViewOpenOpts
---@field cwd   string
---@field kind  FylerWinKind

---@class FylerTreeViewCreateOpts
---@field cwd?   string
---@field kind?  FylerWinKind
---@field config FylerConfig

---@param opts FylerTreeViewCreateOpts
---@return FylerTreeView
local function create_view(opts)
  local instance = {
    cwd = opts.cwd,
    count = M.count,
    store = M.store,
    config = opts.config,
  }

  setmetatable(instance, vim.tbl_deep_extend("force", FileTreeView, view_mt))

  return instance
end

---@param opts FylerTreeViewCreateOpts
function M.open(opts)
  assert(opts, "opts is required")
  assert(opts.config, "config is required")

  local win = opts.config.get_win(view_name)
  local cwd = opts.cwd or fs.getcwd()
  local kind = opts.kind or win.kind

  local existing_instance = vim.iter(M.instances):find(function(instance)
    return instance.cwd == cwd
  end)

  if existing_instance then
    existing_instance:open(opts)
  else
    local instance = create_view(opts)
    table.insert(M.instances, instance)
    instance:open { cwd = cwd, kind = kind }
  end
end

---@param cwd string
---@return FylerTree?
local function build_tree(cwd)
  assert(cwd, "cwd is required")

  local stats = uv.fs_stat(cwd) or {}
  if stats.type ~= "directory" then
    return nil
  end

  M.count = M.count + 1

  local tree = Tree.new(tree_mt, {
    key = M.count,
    open = true,
    name = fn.fnamemodify(cwd, ":t"),
    type = "directory",
    path = cwd,
  })

  M.store[M.count] = cwd

  local items, err = fs.listdir(cwd)
  if err then
    return tree
  end

  for _, item in ipairs(items) do
    M.count = M.count + 1
    M.store[M.count] = item.path
    tree:add("path", cwd, vim.tbl_deep_extend("force", item, { key = M.count }))
  end

  return tree
end

---@param opts FylerTreeViewOpenOpts
function FileTreeView:open(opts)
  local config = self.config
  local mappings = config.get_reverse_mappings(view_name)

  self.tree = self.tree or build_tree(opts.cwd)

  self.win = Win.new {
    enter = true,
    name = view_name,
    kind = opts.kind,
    bufopts = {
      syntax = "fyler",
      filetype = "fyler",
    },
    winopts = {
      conceallevel = 3,
      concealcursor = "nvic",
    },
    -- stylua: ignore start
    mappings = {
      n = {
        [mappings["CloseView"]]  = self:_action("n_close_view"),
        [mappings["ToggleOpen"]] = self:_action("n_toggle_open"),
      },
    },
    -- stylua: ignore end
    autocmds = {
      ["WinClosed"] = self:_action("n_close_view"),
    },
    render = function()
      if self.tree then
        return ui.FileTree(self.tree:totable().children)
      else
        return {}
      end
    end,
  }

  self.win:show()
end

function FileTreeView:close()
  self.win:hide()
end

---@param name string
function FileTreeView:_action(name)
  local action = require("fyler.views.file_tree.actions")[name]

  assert(action, ("action(%s)"):format(name))

  return action(self)
end

return M

local Tree = require("fyler.lib.structures.tree")
local Win = require("fyler.lib.win")
local fs = require("fyler.lib.fs")
local ui = require("fyler.views.file_tree.ui")

---@class FylerTreeViewOpenOpts
---@field cwd  string
---@field kind FylerWinKind

---@class FylerTreeView
---@field win FylerWin
---@field config FylerConfig
local M = {}
M.__index = M

---@param config FylerConfig
---@return FylerTreeView
function M.new(config)
  assert(config, "config is required")

  local instance = {
    config = config,
  }

  return setmetatable(instance, M)
end

local tree_mt = {
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
  __eq = function(a, b)
    local ad = a.data
    local bd = b.data

    return ad.name == bd.name and ad.type == bd.type and ad.path == bd.path
  end,
}

---@param root_path string
---@return FylerTree
local function build_tree(root_path)
  local lst = fs.listdir(root_path)
  local tree = Tree.new(tree_mt, {
    path = root_path,
  })

  for _, item in ipairs(lst) do
    tree:add("path", root_path, {
      name = item.name,
      type = item.type,
      path = item.path,
    })
  end

  return tree
end

---@param opts FylerTreeViewOpenOpts
function M:open(opts)
  opts = opts or {}

  local view_name = "tree_view"
  local config = self.config
  local win = config.get_win(view_name)
  local mappings = config.get_reverse_mappings(view_name)

  local tree = build_tree(opts.cwd or fs.getcwd())

  self.win = Win.new {
    enter = true,
    name = view_name,
    kind = opts.kind or win.kind,
    filetype = view_name,
    mappings = {
      n = {
        [mappings["CloseView"]] = self:_action("n_close_view"),
      },
    },
    autocmds = {
      ["WinClosed"] = self:_action("n_close_view"),
    },
    render = function()
      return ui.FileTree(tree:totable().children)
    end,
  }

  self.win:show()
end

function M:close()
  self.win:hide()
end

---@param name string
function M:_action(name)
  local action = require("fyler.views.file_tree.actions")[name]

  assert(action, ("action(%s)"):format(name))

  return action(self)
end

return M

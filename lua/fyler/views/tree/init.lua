local Win = require("fyler.lib.win")
local ui = require("fyler.views.tree.ui")

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

---@param opts FylerTreeViewOpenOpts
function M:open(opts)
  opts = opts or {}

  local view_name = "tree_view"
  local config = self.config
  local win = config.get_win(view_name)
  local mappings = config.get_reverse_mappings(view_name)

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
      return ui.Tree()
    end,
  }

  self.win:show()
end

function M:close()
  self.win:hide()
end

---@param name string
function M:_action(name)
  local action = require("fyler.views.tree.actions")[name]

  assert(action, ("action(%s)"):format(name))

  return action(self)
end

return M

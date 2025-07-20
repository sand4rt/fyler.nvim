local Win = require("fyler.lib.win")
local config = require("fyler.config")
local ui = require("fyler.views.confirm.ui")

---@class FylerConfirmView
---@field win FylerWin
local FylerConfirmView = {}
FylerConfirmView.__index = FylerConfirmView

---@param msg { str: string, hl: string }[]
---@param chs string
---@param cb fun(c: boolean)
function FylerConfirmView:open(msg, chs, cb)
  local mappings = config.get_reverse_mappings("confirm")
  local view = config.get_view("confirm")

  --stylua: ignore start
  self.win = Win {
    enter   = true,
    bufname = "confirm",
    width   = view.width,
    height  = view.height,
    border  = view.border,
    kind    = view.kind,
    bufopts = {
      buflisted  = false,
      modifiable = false,
    },
    name = "confirm",
    title = string.format(" Confirm %s ", chs),
    winopts = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder,FloatTitle:FloatTitle",
      wrap         = false,
    },
    mappings = {
      n = {
        [mappings["Confirm"]] = self:_action("n_confirm", cb),
        [mappings["Discard"]] = self:_action("n_discard", cb),
      },
    },
    autocmds = {
      ["QuitPre"] = self:_action("n_close_view", cb),
    },
    render = function()
      return { lines = ui.Confirm(msg) }
    end,
  }
  --stylua: ignore end

  self.win:show()
end

function FylerConfirmView:close()
  self.win:hide()
end

---@param name string
function FylerConfirmView:_action(name, ...)
  local action = require("fyler.views.confirm.actions")[name]

  assert(action, string.format("%s action is not available", name))

  return action(self, ...)
end

local M = {}

---@param msg { str: string, hl: string }[]
---@param chs string
---@param cb fun(c: boolean)
M.open = vim.schedule_wrap(function(msg, chs, cb)
  if not M.instance then
    M.instance = setmetatable({}, FylerConfirmView)
  end

  if M.instance.win and M.instance.win:has_valid_winid() then
    M.instance:close()
  end

  M.instance:open(msg, chs, cb)
end)

return M

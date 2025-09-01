local Win = require "fyler.lib.win"
local a = require "fyler.lib.async"
local Line = require("fyler.lib.ui.components").Line
local util = require "fyler.lib.util"

---@class PopupPermission
---@field win Win
local M = {}
M.__index = M

---@param self PopupPermission
---@param message table
---@param on_choice fun(choice: boolean)
M.open = a.wrap(vim.schedule_wrap(function(self, message, on_choice)
  self.win = Win.new {
    border = "rounded",
    buf_opts = { modifiable = false },
    enter = true,
    height = "0.3rel",
    kind = "float",
    left = "0.3rel",
    mappings = {
      ["y"] = self:_action("accept", on_choice),
      ["n"] = self:_action("reject", on_choice),
    },
    render = function()
      self.win.ui:render {
        ui_lines = util.tbl_map(
          message,
          function(line)
            return Line.new {
              words = line,
            }
          end
        ),
      }
    end,
    top = "0.35rel",
    width = "0.4rel",
  }

  self.win:show()
end))

local actions = {
  ---@param self { win: Win }
  ---@param on_choice fun(choice: boolean)
  accept = function(self, on_choice)
    return function()
      self.win:hide()
      on_choice(true)
    end
  end,

  ---@param self { win: Win }
  ---@param on_choice fun(choice: boolean)
  reject = function(self, on_choice)
    return function()
      self.win:hide()
      on_choice(false)
    end
  end,
}

---@param name string
function M:_action(name, ...)
  local action = actions[name]
  assert(action, string.format("action %s is not available", name))

  return action(self, ...)
end

return M

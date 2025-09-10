local Popup = require "fyler.lib.popup"
local a = require "fyler.lib.async"
local ui = require "fyler.popups.permission.ui"

---@class PopupPermission
local M = {}
M.__index = M

---@param message { str: string, hlg: string }[]
---@param on_choice fun(choice: boolean)
M.create = a.wrap(vim.schedule_wrap(function(message, on_choice)
  Popup.new()
    :enter()
    :border(vim.fn.has "nvim-0.11" == 1 and vim.o.winborder or "rounded")
    :buf_opt("modifiable", false)
    :height("0.3rel")
    :kind("float")
    :left("0.3rel")
    :top("0.35rel")
    :width("0.4rel")
    :action("y", function(self)
      return function()
        self.win:hide()
        on_choice(true)
      end
    end)
    :action("n", function(self)
      return function()
        self.win:hide()
        on_choice(false)
      end
    end)
    :render(function(self)
      return function()
        self.win.ui:render {
          ui_lines = ui(message),
        }
      end
    end)
    :create()
end))

return M

local Popup = require "fyler.lib.popup"
local a = require "fyler.lib.async"
local config = require "fyler.config"
local ui = require "fyler.popups.permission.ui"

---@class PopupPermission
local M = {}
M.__index = M

---@return function
local function hide_cursor()
  vim.api.nvim_set_hl(0, "FylerHiddenCursor", { nocombine = true, blend = 100 })

  local guicursor = vim.go.guicursor
  vim.go.guicursor = "a:FylerHiddenCursor/FylerHiddenCursor"

  return function()
    vim.go.guicursor = "a:"
    vim.cmd.redrawstatus()
    vim.go.guicursor = guicursor
  end
end

---@param message { str: string, hlg: string }[]
---@param on_choice fun(choice: boolean)
M.create = a.wrap(vim.schedule_wrap(function(message, on_choice)
  local popup = config.build_popup "permission"
  --TODO: Should find a better way to hide and show cursor
  local show_cursor = hide_cursor()

  Popup.new()
    :action("y", function(self)
      return function()
        self.win:hide()

        show_cursor()
        on_choice(true)
      end
    end)
    :action("n", function(self)
      return function()
        self.win:hide()

        show_cursor()
        on_choice(false)
      end
    end)
    :border(popup.border)
    :buf_opt("modifiable", false)
    :enter()
    :height(popup.height)
    :kind("float")
    :left(popup.left)
    :on_show(function() end)
    :on_hide(function() end)
    :render(function(self)
      return function()
        self.win.ui:render(ui(message))
      end
    end)
    :top(popup.top)
    :width(popup.width)
    :create()
end))

return M

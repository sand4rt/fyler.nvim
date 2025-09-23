local UiComponent = require "fyler.lib.ui.component"
local M = {}

---@param children UiComponent[]
M.Column = UiComponent.new(function(children)
  return {
    tag = "column",
    children = children,
  }
end)

---@param children UiComponent[]
M.Row = UiComponent.new(function(children)
  return {
    tag = "row",
    children = children,
  }
end)

M.Text = UiComponent.new(function(value, option)
  return {
    tag = "text",
    value = value,
    option = option,
    children = {},
  }
end)

M.Extmark = UiComponent.new(function(options)
  return {
    tag = "extmark",
    option = options,
    children = {},
  }
end)

return M

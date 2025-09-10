local UiComponent = require "fyler.lib.ui.component"
local M = {}

---@alias UiLineAlign
---| "end"
---| "start"
---| "center"

---@alias UiWord { str: string, hl: string|nil }
---@alias UiMark { str: string, hl: string|nil, id: string }

---@class UiLine
---@field align UiLineAlign
---@field words UiWord[]
---@field marks UiMark[]
M.Line = {}
M.Line.__index = M.Line

---@param opts { words: UiWord[], marks: UiMark[], align: UiLineAlign|nil }
---@return UiLine
function M.Line.new(opts)
  local instance = {
    words = opts.words or {},
    align = opts.align or "start",
    marks = opts.marks or {},
  }

  setmetatable(instance, M.Line)

  return instance
end

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

M.Text = UiComponent.new(
  function(value, option)
    return {
      tag = "text",
      value = value,
      option = option,
      children = {},
    }
  end
)

M.Extmark = UiComponent.new(
  function(options)
    return {
      tag = "extmark",
      option = options,
      children = {},
    }
  end
)

return M

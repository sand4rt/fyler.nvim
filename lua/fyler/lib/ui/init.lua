local Component = require "fyler.lib.ui.component"
local Renderer = require "fyler.lib.ui.renderer"
local util = require "fyler.lib.util"

local api = vim.api

---@class Ui
---@field win Win
---@field renderer UiRenderer
local Ui = {}
Ui.__index = Ui

---@param win Win
---@return Ui
function Ui.new(win)
  local instance = {
    win = win,
    renderer = Renderer.new(),
  }

  setmetatable(instance, Ui)

  return instance
end

---@param component UiComponent
function Ui:_render(component)
  if not self.win:has_valid_bufnr() then
    return
  end

  local was_modifiable = util.get_buf_option(self.win.bufnr, "modifiable")
  util.set_buf_option(self.win.bufnr, "modifiable", true)

  self.renderer:render(component)

  api.nvim_buf_set_lines(self.win.bufnr, 0, -1, false, self.renderer.line)
  api.nvim_buf_clear_namespace(self.win.bufnr, self.win.namespace, 0, -1)

  for _, highlight in ipairs(self.renderer.highlight) do
    api.nvim_buf_set_extmark(self.win.bufnr, self.win.namespace, highlight.line, highlight.col_start, {
      end_col = highlight.col_end,
      hl_group = highlight.highlight_group,
    })
  end

  for _, extmark in ipairs(self.renderer.extmark) do
    api.nvim_buf_set_extmark(self.win.bufnr, self.win.namespace, extmark.line, 0, {
      virt_text = extmark.virt_text,
      virt_text_pos = extmark.virt_text_pos,
      virt_text_win_col = extmark.col,
      hl_mode = extmark.hl_mode,
    })
  end

  if not was_modifiable then
    util.set_buf_option(self.win.bufnr, "modifiable", false)
  end

  util.set_buf_option(self.win.bufnr, "modified", false)
end

function Ui:render(opts)
  opts = opts or {}

  vim.schedule(function()
    if opts.before then
      opts.before()
    end

    self:_render(opts.ui_lines)

    if opts.after then
      opts.after()
    end
  end)
end

Ui.Component = Component

---@param children UiComponent[]
Ui.Column = Ui.Component.new(function(children)
  return {
    tag = "column",
    children = children,
  }
end)

---@param children UiComponent[]
Ui.Row = Ui.Component.new(function(children)
  return {
    tag = "row",
    children = children,
  }
end)

Ui.Text = Ui.Component.new(function(value, option)
  return {
    tag = "text",
    value = value,
    option = option,
    children = {},
  }
end)

return Ui

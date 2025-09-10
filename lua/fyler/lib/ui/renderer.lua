---@class UiRenderer
---@field line string[]
---@field extmark table[]
---@field highlight table[]
---@field flag table
local Renderer = {}
Renderer.__index = Renderer

function Renderer.new()
  local instance = {
    line = {},
    highlight = {},
    extmark = {},
    flag = {
      in_row = false,
    },
  }

  setmetatable(instance, Renderer)

  return instance
end

---@param component UiComponent
---@return string[], table[]
function Renderer:render(component)
  self.line = {}
  self.highlight = {}
  self.extmark = {}
  self:_render(component)
  return self.line, self.highlight
end

---@param component UiComponent
---@param current_col number|nil
---@return string|nil, number|nil
function Renderer:_render_text(component, current_col)
  local text_value = tostring(component.value or "")
  local highlight = component.option and component.option.highlight

  if component.option and component.option.virt_text then
    local line_num = self.flag.in_row and #self.line or (#self.line - 1)

    line_num = math.max(0, line_num)
    local col_position = self.flag.in_row and (current_col or 0) or 0

    table.insert(self.extmark, {
      line = line_num,
      col = component.option.col or col_position,
      virt_text = component.option.virt_text,
      virt_text_pos = "overlay",
      hl_mode = "combine",
    })
  end

  if self.flag.in_row then
    current_col = current_col or 0

    if highlight then
      table.insert(self.highlight, {
        line = #self.line,
        col_start = current_col,
        col_end = current_col + #text_value,
        highlight_group = highlight,
      })
    end

    return text_value, current_col + #text_value
  else
    if text_value then table.insert(self.line, text_value) end

    if highlight then
      table.insert(self.highlight, {
        line = #self.line - 1,
        col_start = 0,
        col_end = #text_value,
        highlight_group = highlight,
      })
    end
  end
end

---@param component UiComponent
---@param current_col number|nil
---@return string|nil, number|nil
function Renderer:_render_child_in_row(component, current_col)
  if component.tag == "text" then
    return self:_render_text(component, current_col)
  else
    error("The row component does not support having a `" .. component.tag .. "` as a child")
  end
end

---@param component UiComponent
function Renderer:_render_row(component)
  self.flag.in_row = true

  local row_parts = {}
  local current_col = 0

  for _, child in ipairs(component.children) do
    local text_part, new_col = self:_render_child_in_row(child, current_col)
    if text_part then
      table.insert(row_parts, text_part)
      current_col = new_col or current_col
    end
  end

  table.insert(self.line, table.concat(row_parts))

  local current_line = #self.line - 1
  for i = #self.extmark, 1, -1 do
    local extmark = self.extmark[i]
    if extmark.line == #self.line then
      extmark.line = current_line
    else
      break
    end
  end

  for i = #self.highlight, 1, -1 do
    local highlight = self.highlight[i]
    if highlight.line == #self.line then
      highlight.line = current_line
    else
      break
    end
  end

  self.flag.in_row = false
end

---@param component UiComponent
function Renderer:_render_column(component)
  for _, child in ipairs(component.children) do
    self:_render_child(child)
  end
end

---@param component UiComponent
function Renderer:_render_child(component)
  if component.tag == "text" then
    self:_render_text(component)
  elseif component.tag == "column" then
    self:_render_column(component)
  elseif component.tag == "row" then
    self:_render_row(component)
  else
    for _, child in ipairs(component.children) do
      self:_render_child(child)
    end
  end
end

---@param component UiComponent
function Renderer:_render(component)
  if self.flag.in_row then
    for _, child in ipairs(component.children) do
      self:_render_child_in_row(child)
    end
  else
    if component.children then
      for _, child in ipairs(component.children) do
        self:_render_child(child)
      end
    end
  end
end

return Renderer

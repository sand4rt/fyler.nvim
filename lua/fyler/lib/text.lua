local helper = require 'fyler.lib.ui.helper'
local api = vim.api
---@alias Fyler.Text.Word { str: string, hl: string }
---@alias Fyler.Text.Line { words: Fyler.Text.Word[] }

---@class Fyler.Text.Options
---@field left_margin? integer

---@class Fyler.Text : Fyler.Text.Options
---@field lines Fyler.Text.Line[]
local Text = {}
Text.__index = Text
Text.__concat = function(t1, t2)
  if #t1.lines == 0 then
    return t2
  end

  if #t2.lines == 0 then
    return t1
  end

  local result = Text.new {}
  result.lines = {}
  for _, line in ipairs(t1.lines) do
    table.insert(result.lines, line)
  end

  for _, word in ipairs(t2.lines[1].words) do
    table.insert(result.lines[#result.lines].words, word)
  end

  for i = 2, #t2.lines do
    table.insert(result.lines, t2.lines[i])
  end

  return result
end

---@param options? Fyler.Text.Options
---@return Fyler.Text
function Text.new(options)
  return setmetatable({}, Text):init(options)
end

---@param options? Fyler.Text.Options
---@return Fyler.Text
function Text:init(options)
  options = options or {}
  self.left_margin = options.left_margin or 0
  self.lines = { { words = {} } }

  return self
end

---@param count? integer
---@return Fyler.Text
function Text:nl(count)
  for _ = 1, (count or 1) do
    table.insert(self.lines, { words = {} })
  end

  return self
end

---@param str string
---@param hl? string
---@return Fyler.Text
function Text:append(str, hl)
  table.insert(self.lines[#self.lines].words, { str = str, hl = hl or 'FylerBlank' })

  return self
end

---@return Fyler.Text
function Text:trim()
  while #self.lines >= 1 and vim.tbl_isempty(self.lines[#self.lines].words) do
    table.remove(self.lines)
  end

  return self
end

---@param bufnr integer
function Text:render(bufnr)
  vim.schedule(function()
    local ns_highlights = vim.api.nvim_create_namespace 'FylerHighlight'
    local start_line = 0
    if not helper.is_valid_bufnr(bufnr) then
      return
    end

    local was_modifiable = vim.bo[bufnr].modifiable
    if not was_modifiable then
      vim.bo[bufnr].modifiable = true
    end

    local virt_lines = {}
    for _, line in ipairs(self.lines) do
      local text = string.rep(' ', self.left_margin)
      for _, word in ipairs(line.words) do
        text = text .. word.str
      end
      table.insert(virt_lines, text)
    end

    api.nvim_buf_set_lines(bufnr, 0, -1, false, virt_lines)
    api.nvim_buf_clear_namespace(bufnr, ns_highlights, 0, -1)
    for i, line in ipairs(self.lines) do
      local col = self.left_margin
      for _, segment in ipairs(line.words) do
        if segment.hl and segment.hl ~= '' then
          api.nvim_buf_set_extmark(bufnr, ns_highlights, start_line + i - 1, col, {
            end_col = col + #segment.str,
            hl_group = segment.hl,
          })
        end
        col = col + #segment.str
      end
    end

    if not was_modifiable then
      vim.bo[bufnr].modifiable = false
    end

    vim.bo[bufnr].modified = false
  end)
end

---@return integer
function Text:span()
  local max_span = 0
  for _, line in ipairs(self.lines) do
    local curr_span = 0
    for _, word in ipairs(line.words) do
      curr_span = curr_span + #word.str
    end

    max_span = math.max(max_span, curr_span)
  end

  return max_span
end

---@param cnt integer
function Text:pl(cnt)
  for _, line in ipairs(self.lines) do
    table.insert(line.words, 1, { str = string.rep(' ', cnt), hl = 'FylerBlank' })
  end

  return self
end

return Text

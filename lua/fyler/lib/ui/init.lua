local api = vim.api

---@class FylerUi
---@field win FylerWin
local Ui = {}
Ui.__index = Ui

---@param win FylerWin
---@return FylerUi
function Ui.new(win)
  assert(win, "win is required")

  local instance = {
    win = win,
  }

  setmetatable(instance, Ui)
  return instance
end

---@param lines FylerUiLine[]
function Ui:_render(lines)
  if not self.win:has_valid_bufnr() then
    return
  end

  -- Check the `modifiable` porperty to restore it after completion of render
  local was_modifiable = vim.bo[self.win.bufnr].modifiable
  local buf_lines = {}

  vim.bo[self.win.bufnr].modifiable = true

  -- Going through each line
  for _, line in ipairs(lines) do
    local buf_line = ""

    -- Going through each word
    for _, word in ipairs(line.words) do
      buf_line = buf_line .. word.str
    end

    table.insert(buf_lines, buf_line)
  end

  api.nvim_buf_set_lines(self.win.bufnr, 0, -1, false, buf_lines)
  api.nvim_buf_clear_namespace(self.win.bufnr, self.win.namespace, 0, -1)

  for i, line in ipairs(lines) do
    local offset = 0

    for _, word in ipairs(line.words) do
      api.nvim_buf_set_extmark(self.win.bufnr, self.win.namespace, i - 1, offset, {
        end_col = offset + #word.str,
        hl_group = word.hl,
      })

      offset = offset + #word.str
    end
  end

  if not was_modifiable then
    vim.bo[self.win.bufnr].modifiable = false
  end

  vim.bo[self.win.bufnr].modified = false
end

---@param lines FylerUiLine[]
function Ui:render(lines)
  vim.schedule(function()
    self:_render(lines)
  end)
end

return Ui

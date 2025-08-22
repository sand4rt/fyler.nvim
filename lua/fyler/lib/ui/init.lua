local util = require("fyler.lib.util")

local api = vim.api

---@class FylerUi
---@field win FylerWin
local Ui = {}
Ui.__index = Ui

---@param win FylerWin
---@return FylerUi
function Ui.new(win)
  assert(win, "win is required")
  return setmetatable({ win = win }, Ui)
end

---@param align FylerUiLineAlign
---@param line string
---@return string
local function get_margin(width, align, line)
  if align == "center" then
    return string.rep(" ", math.floor((width - #line) * 0.5))
  elseif align == "end" then
    return string.rep(" ", math.floor((width - #line)))
  else
    return ""
  end
end

---@param ui_lines FylerUiLine[]
function Ui:_render(ui_lines)
  if not self.win:has_valid_bufnr() then return end

  local buf_lines = {}
  local was_modifiable = util.get_buf_option(self.win.bufnr, "modifiable")
  local win_width = api.nvim_win_get_width(self.win.winid)
  util.set_buf_option(self.win.bufnr, "modifiable", true)

  for _, line in ipairs(ui_lines) do
    local line_text = table.concat(vim.tbl_map(function(word) return word.str end, line.words))
    local margin = get_margin(win_width, line.align, line_text)
    table.insert(line.words, 1, { str = margin })
    table.insert(buf_lines, margin .. line_text)
  end

  api.nvim_buf_set_lines(self.win.bufnr, 0, -1, false, buf_lines)
  api.nvim_buf_clear_namespace(self.win.bufnr, self.win.namespace, 0, -1)

  for i, line in ipairs(ui_lines) do
    local offset = 0
    for _, word in ipairs(line.words) do
      api.nvim_buf_set_extmark(self.win.bufnr, self.win.namespace, i - 1, offset, {
        end_col = offset + #word.str,
        hl_group = word.hl or "",
      })

      offset = offset + #word.str
    end

    for _, mark in pairs(line.marks) do
      api.nvim_buf_set_extmark(self.win.bufnr, self.win.namespace, i - 1, 0, {
        virt_text = { { mark.str, mark.hl or "" } },
        virt_text_pos = "eol",
        hl_mode = "combine",
      })
    end
  end

  if not was_modifiable then util.set_buf_option(self.win.bufnr, "modifiable", false) end

  util.set_buf_option(self.win.bufnr, "modified", false)
end

function Ui:render(opts)
  opts = opts or {}

  vim.schedule(function()
    if opts.before then opts.before() end

    self:_render(opts.ui_lines)

    if opts.after then opts.after() end
  end)
end

return Ui

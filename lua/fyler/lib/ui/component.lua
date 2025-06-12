local helper = require 'fyler.lib.ui.helper'
local api = vim.api
local M = {}

---@param text Fyler.Text
---@param callback function
M.confirm = vim.schedule_wrap(function(text, callback)
  local _, vh = helper.get_view_size()
  local window_options = {
    enter = true,
    width = 1,
    height = 0,
    height_delta = #text.lines + 1,
    col = 0,
    row = 0,
    border = { '', '─', '', '', '', '─', '', '' },
  }
  window_options.row_delta = math.floor((vh - window_options.height_delta) * 0.5)

  local window = require('fyler.lib.ui.window').new(window_options)
  local restore_cursor = helper.hide_cursor()
  helper.show_window(window)

  vim.bo[window.bufnr].modifiable = false
  vim.wo[window.winid].winhighlight = table.concat({
    'Normal:Normal',
    'FloatBorder:FloatBorder',
    'FloatTitle:FloatTitle',
  }, ',')

  api.nvim_create_autocmd('WinClosed', {
    group = api.nvim_create_augroup('Fyler', { clear = true }),
    buffer = window.bufnr,
    callback = function()
      helper.hide_window(window)
      restore_cursor()
    end,
  })

  vim.keymap.set('n', 'y', function()
    helper.hide_window(window)
    restore_cursor()
    callback(true)
  end, { buffer = window.bufnr, silent = true, noremap = true })

  vim.keymap.set('n', 'n', function()
    helper.hide_window(window)
    restore_cursor()
    callback(false)
  end, { buffer = window.bufnr, silent = true, noremap = true })

  local button_success = ' [Y]Confirm '
  local button_failure = ' [N]Discard '
  local columns = api.nvim_win_get_width(window.winid)
  local total_width = #(button_success .. button_failure)
  local left_padding = math.floor((columns - total_width) * 0.5)
  text
    :pl(math.floor((columns - text:span()) * 0.5))
    :nl()
    :append(string.rep(' ', left_padding))
    :append(button_success, 'FylerSuccess')
    :append(button_failure, 'FylerFailure')
    :render(window.bufnr)
end)

return M

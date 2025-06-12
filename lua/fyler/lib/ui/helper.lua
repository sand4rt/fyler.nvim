local api = vim.api
local M = {}

---@return integer, integer
function M.get_view_size()
  local vw = vim.o.columns
  local vh = vim.o.lines - vim.o.cmdheight
  if vim.o.laststatus ~= 0 then
    vh = vh - 1
  end

  return vw, vh
end

---@param bufnr integer
---@return boolean
function M.is_valid_bufnr(bufnr)
  return type(bufnr) == 'number' and api.nvim_buf_is_valid(bufnr)
end

---@param winid integer
---@return boolean
function M.is_valid_winid(winid)
  return type(winid) == 'number' and api.nvim_win_is_valid(winid)
end

---@param window Fyler.Window
---@return boolean
function M.has_valid_bufnr(window)
  return type(window.bufnr) == 'number' and api.nvim_buf_is_valid(window.bufnr)
end

---@param window Fyler.Window
---@return boolean
function M.has_valid_winid(window)
  return type(window.winid) == 'number' and api.nvim_win_is_valid(window.winid)
end

---@return function
function M.hide_cursor()
  local original_guicursor = vim.go.guicursor
  vim.go.guicursor = 'a:FylerHiddenCursor/FylerHiddenCursor'

  return function()
    vim.go.guicursor = 'a:'
    if original_guicursor ~= '' then
      vim.go.guicursor = original_guicursor
    end
  end
end

---@param window Fyler.Window
function M.show_window(window)
  if M.has_valid_winid(window) then
    return
  end

  window.bufnr = api.nvim_create_buf(false, true)
  window.winid = api.nvim_open_win(window.bufnr, window.enter, M.get_win_config(window))
end

---@param window Fyler.Window
function M.hide_window(window)
  if M.has_valid_winid(window) then
    api.nvim_win_close(window.winid, true)
  end

  if M.has_valid_bufnr(window) then
    api.nvim_buf_delete(window.bufnr, { force = true })
  end
end

---@param window Fyler.Window
function M.resize_window(window)
  if M.has_valid_winid(window) then
    api.nvim_win_set_config(window.winid, M.get_win_config(window))
  end
end

---@param window Fyler.Window
---@return vim.api.keyset.win_config
function M.get_win_config(window)
  if window.split then
    return {
      style = 'minimal',
      width = math.ceil(window.width * vim.o.columns),
      split = window.split,
    }
  else
    local vw, vh = require('fyler.lib.ui.helper').get_view_size()
    return {
      relative = 'editor',
      style = 'minimal',
      width = math.min(math.ceil(window.width * vim.o.columns) + (window.width_delta or 0), vw),
      height = math.min(math.ceil(window.height * vim.o.lines) + (window.height_delta or 0), vh),
      col = math.min(math.floor(window.col * vw) + (window.col_delta or 0), vw),
      row = math.min(math.floor(window.row * vh) + (window.row_delta or 0), vh),
      border = window.border,
    }
  end
end

---@param bufnr integer
---@param word string
---@return integer?
function M.find_word_line_from_buffer(bufnr, word)
  local buf_lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for index, line in ipairs(buf_lines) do
    if line:find(word) then
      return index
    end
  end

  return nil
end

return M

local algos = require 'fyler.lib.algos'
local config = require 'fyler.lib.config'
local fs = require 'fyler.lib.fs'
local helper = require 'fyler.lib.ui.helper'
local state = require 'fyler.lib.state'
local api = vim.api
local M = {}

function M.toggle_reveal()
  local current_line = api.nvim_get_current_line()
  local meta_key = algos.extract_meta_key(current_line)
  local window = state.get { 'window', 'main' }
  local recent_winid = state.get { 'recent', 'winid' }
  local node = state.get { 'node', state.get { 'cwd' } }
  local metadata = state.get { 'meta', tostring(meta_key) }
  if metadata.type == 'directory' then
    local target_node = node:find(metadata.path)
    if target_node then
      target_node.revealed = not target_node.revealed
      node:totext():trim():render(window.bufnr)
    end
  else
    if recent_winid and helper.is_valid_winid(recent_winid) then
      vim.fn.win_execute(recent_winid, string.format('edit %s', metadata.path))
      vim.fn.win_gotoid(recent_winid)
      if config.values.close_on_open then
        helper.hide_window(window)
      end
    else
      vim.cmd(string.format('edit %s', metadata.path))
      state.set({ 'recent', 'winid' }, api.nvim_get_current_win())
      state.set({ 'window', 'main' }, nil)
    end
  end
end

function M.synchronize()
  local node = state.get { 'node', state.get { 'cwd' } }
  local window = state.get { 'window', 'main' }
  fs.synchronize_from_buffer(function()
    node:totext():trim():render(window.bufnr)
  end)
end

return M

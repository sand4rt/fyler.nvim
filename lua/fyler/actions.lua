local algos = require 'fyler.algos'
local filesystem = require 'fyler.filesystem'
local state = require 'fyler.state'
local utils = require 'fyler.utils'
local actions = {}
local uv = vim.uv or vim.loop

function actions.close_current()
  local match = vim.bo.filetype:match '^[^-]+-(.+)$'
  if match then
    utils.hide_window(state.window[match])
  end
end

function actions.toggle_reveal()
  local current_line = vim.api.nvim_get_current_line()
  local meta_key = algos.extract_meta_key(current_line)
  local window = state.window.main
  local user_winid = state.window_id.user
  local render_node = state.render_node[uv.cwd() or vim.fn.getcwd(0)]
  local metadata = state.meta_data[meta_key]
  if metadata.type == 'directory' then
    render_node:toggle_reveal(metadata.path)
    render_node:get_equivalent_text():remove_trailing_empty_lines():render(window.bufnr)
  else
    vim.fn.win_execute(user_winid, string.format('edit %s', metadata.path))
    vim.fn.win_gotoid(user_winid)
  end
end

function actions.synchronize()
  local render_node = state.render_node[uv.cwd() or vim.fn.getcwd(0)]
  local window = state.window.main
  filesystem.synchronize_from_buffer()
  render_node:get_equivalent_text():remove_trailing_empty_lines():render(window.bufnr)
end

return require('fyler.lib.action').transform_mod(actions)

local state = require 'fyler.state'
local utils = require 'fyler.utils'
local actions = {}

function actions.close_current()
  local match = vim.bo.filetype:match '^[^-]+-(.+)$'
  if match then
    utils.hide_window(state('windows'):get(match))
  end
end

function actions.toggle_reveal()
  local current_line = vim.api.nvim_get_current_line()
  local meta_key = current_line:match '^/(%d+)'
  local window = state('windows'):get 'main' ---@type Fyler.Window
  local user_winid = state('winids'):get 'user'
  local render_node = state('rendernodes'):get((vim.uv or vim.loop).cwd() or vim.fn.getcwd(0)) ---@type Fyler.RenderNode
  local metadata = state('metadata'):get(meta_key)
  if metadata.type == 'directory' then
    render_node:toggle_reveal(metadata.path)
    render_node:get_equivalent_text():remove_trailing_empty_lines():render(window.bufnr)
  else
    vim.fn.win_execute(user_winid, string.format('edit %s', metadata.path))
    vim.fn.win_gotoid(user_winid)
  end
end

return require('fyler.lib.action').transform_mod(actions)

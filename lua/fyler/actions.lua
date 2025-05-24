local state = require 'fyler.state'
local utils = require 'fyler.utils'
local actions = {}

function actions.close_current()
  local match = vim.bo.filetype:match '^[^-]+-(.+)$'

  if match then
    utils.hide_window(state('windows'):get(string.format('fyler%swindow', match)))
  end
end

function actions.toggle_reveal()
  local current_line = vim.api.nvim_get_current_line()
  local meta_key = current_line:match '^/(%d+)'
  local window = state('windows'):get 'main' ---@type Fyler.Window
  local render_node = state('rendernodes'):get((vim.uv or vim.loop).cwd() or vim.fn.getcwd(0)) ---@type Fyler.RenderNode
  render_node:toggle_reveal(state('metakeys'):get(meta_key).path)
  render_node:get_equivalent_text():render(window.bufnr)
end

return require('fyler.lib.action').transform_mod(actions)

local state = require 'fyler.state'
local utils = require 'fyler.utils'
local actions = {}

function actions.close_current()
  local match = vim.bo.filetype:match '^[^-]+-(.+)$'

  if match then
    utils.hide_window(state.get_key(string.format('fyler-%s-window', match)))
  end
end

return require('fyler.lib.action').transform_mod(actions)

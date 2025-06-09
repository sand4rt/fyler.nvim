local algos = require 'fyler.algos'
local config = require 'fyler.config'
local filesystem = require 'fyler.filesystem'
local state = require 'fyler.state'
local utils = require 'fyler.utils'
local actions = {}

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
  local render_node = state.render_node[state.cwd]
  local metadata = state.meta_data[meta_key]
  if metadata.type == 'directory' then
    local target_node = render_node:find(metadata.path)
    if target_node then
      target_node.revealed = not target_node.revealed
      render_node:get_equivalent_text():remove_trailing_empty_lines():render(window.bufnr)
    end
  else
    -- Check if the user window still exists
    if user_winid and vim.api.nvim_win_is_valid(user_winid) then
      vim.fn.win_execute(user_winid, string.format('edit %s', metadata.path))
      vim.fn.win_gotoid(user_winid)

      -- Close the Fyler panel if configured to do so
      if config.values.close_on_open then
        utils.hide_window(window)
      end
    else
      -- User window is gone: open file in current Fyler window
      vim.cmd(string.format('edit %s', metadata.path))
      -- Update the window ID to the current window for future reference
      state.window_id.user = vim.api.nvim_get_current_win()
      -- Reset the Fyler window state since we're reusing this window
      state.window.main = nil
    end
  end
end

function actions.synchronize()
  local render_node = state.render_node[state.cwd]
  local window = state.window.main
  filesystem.synchronize_from_buffer(function()
    render_node:get_equivalent_text():remove_trailing_empty_lines():render(window.bufnr)
  end)
end

function actions._synchronize()
  vim.notify(
    'Save buffer with `:write` to synchronize changes, Key support will no longer be available',
    vim.log.levels.WARN,
    { title = 'fyler.nvim (deprecation warning)' }
  )

  actions.synchronize()
end

return require('fyler.lib.action').transform_mod(actions)

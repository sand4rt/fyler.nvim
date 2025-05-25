local RenderNode = require 'fyler.lib.rendernode'
local Window = require 'fyler.lib.window'
local config = require 'fyler.config'
local state = require 'fyler.state'
local utils = require 'fyler.utils'
local fyler = {}
local luv = vim.uv or vim.loop

function fyler.hide()
  utils.hide_window(state('window'):get 'main')
end

function fyler.show()
  local render_node = RenderNode.new {
    name = vim.fn.fnamemodify(luv.cwd() or '', ':t'),
    path = luv.cwd() or vim.fn.getcwd(0),
    type = 'directory',
    revealed = true,
  }
  local window = Window.new {
    enter = true,
    width = 0.3,
    split = 'right',
  }

  state('windows'):set('main', window)
  state('rendernodes'):set(render_node.path, render_node)
  utils.show_window(window)
  utils.set_buf_option(window, 'filetype', 'fyler-main')
  utils.set_buf_option(window, 'syntax', 'fyler')
  utils.set_win_option(window, 'cursorline', true)
  utils.set_win_option(window, 'conceallevel', 3)
  utils.set_win_option(window, 'concealcursor', 'nvic')
  utils.create_autocmd('WinClosed', {
    buffer = window.bufnr,
    callback = function()
      utils.hide_window(window)
    end,
  })
  utils.create_autocmd('CursorMoved', {
    buffer = window.bufnr,
    callback = function()
      local current_line = vim.api.nvim_get_current_line()
      local meta_key = current_line:match '^/(%d+)'
      if not meta_key then
        return
      end

      local node = render_node:find(state('metakeys'):get(meta_key).path)
      if not node then
        return
      end

      local current_cursor_pos = vim.api.nvim_win_get_cursor(window.winid)
      local desired_cusor_pos = { current_cursor_pos[1], current_line:find(node.name, 1, true) - 1 }

      if current_cursor_pos[2] < desired_cusor_pos[2] then
        vim.api.nvim_win_set_cursor(window.winid, desired_cusor_pos)
      end
    end,
  })

  for mode, mappings in pairs(require('fyler.mappings').default_mappings.main or {}) do
    for k, v in pairs(mappings) do
      utils.set_keymap {
        mode = mode,
        lhs = k,
        rhs = v,
        options = {
          buffer = window.bufnr,
        },
      }
    end
  end

  render_node:get_equivalent_text():render(window.bufnr)
end

function fyler.setup()
  config.set_defaults()
  vim.api.nvim_create_user_command('Fyler', fyler.show, { nargs = 0 })
end

return fyler

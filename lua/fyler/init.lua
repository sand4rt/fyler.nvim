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
  utils.set_buf_option(window, 'filetype', 'fyler')
  utils.set_win_option(window, 'cursorline', true)
  utils.set_win_option(window, 'conceallevel', 3)
  utils.set_win_option(window, 'concealcursor', 'nvic')

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

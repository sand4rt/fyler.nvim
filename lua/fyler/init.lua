local RenderNode = require 'fyler.lib.render-node'
local Window = require 'fyler.lib.window'
local state = require 'fyler.state'
local utils = require 'fyler.utils'
local fyler = {}
local luv = vim.uv or vim.loop

---@param path? string
---@return {name: string, type: string}[]
local function scan_dir(path)
  if not path then
    return {}
  end

  local items = {}
  local fs = luv.fs_scandir(path)

  if not fs then
    return {}
  end

  while true do
    local name, type = luv.fs_scandir_next(fs)

    if not name then
      break
    end

    table.insert(items, { name = name, type = type })
  end

  return items
end

function fyler.hide()
  utils.hide_window(state.get_key 'fyler-main-window')
end

function fyler.show()
  local render_node = RenderNode.new {
    name = vim.fn.fnamemodify(luv.cwd() or '', ':t'),
    type = 'directory',
    revealed = true,
  }
  local window = Window.new {
    enter = true,
    width = 0.3,
    split = 'right',
  }

  state.set_key('fyler-main-window', window)
  state.set_key('render-node', render_node)

  utils.show_window(window)
  utils.set_buf_option(window, 'filetype', 'fyler-main')
  utils.set_win_option(window, 'cursorline', true)

  local results = scan_dir(luv.cwd())

  for _, result in ipairs(results) do
    render_node:add_child(result)
  end

  render_node:get_equivalent_text():render(window.bufnr)

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
end

function fyler.setup()
  require('fyler.config').set_defaults()

  vim.api.nvim_create_user_command('Fyler', fyler.show, { nargs = 0 })
end

return fyler

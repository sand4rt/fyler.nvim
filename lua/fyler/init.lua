local RenderNode = require 'fyler.lib.render-node'
local Text = require 'fyler.lib.text'
local Window = require 'fyler.lib.window'
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
  utils.hide_window(fyler.window)
end

function fyler.show()
  fyler.text = Text.new {}
  fyler.render_node = RenderNode.new {
    name = vim.fn.fnamemodify(vim.uv.cwd() or '', ':t'),
    type = 'directory',
    revealed = true,
  }
  fyler.window = Window.new {
    enter = true,
    width = 0.3,
    split = 'right',
  }

  utils.show_window(fyler.window)
  utils.set_buf_option(fyler.window, 'filetype', 'fyler')
  utils.set_win_option(fyler.window, 'cursorline', true)

  local results = scan_dir(vim.uv.cwd())

  for _, result in ipairs(results) do
    fyler.render_node:add_child(result)
  end

  fyler.render_node:get_equivalent_text():render(fyler.window.bufnr)

  vim.keymap.set('n', 'q', fyler.hide, { desc = 'fyler.nvim close' })
end

function fyler.setup()
  require('fyler.config').set_defaults()

  vim.api.nvim_create_user_command('Fyler', fyler.show, { nargs = 0 })
end

return fyler

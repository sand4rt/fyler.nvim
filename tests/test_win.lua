local test = require 'mini.test'
local T = test.new_set()

T['can create instance'] = function()
  local kinds = {
    'float',
    'split:left',
    'split:above',
    'split:right',
    'split:below',
  }

  local opts = {
    name = 'FylerTest',
    kind = kinds[math.random(1, 5)],
    enter = true,
    mappings = {},
  }

  local win = require('fyler.lib.win').new(opts)

  for key, val in pairs(opts) do
    test.expect.equality(win[key], val)
  end
end

T['can show and hide'] = function()
  local kinds = {
    'float',
    'split:left',
    'split:above',
    'split:right',
    'split:below',
  }

  local win = require('fyler.lib.win').new {
    name = 'file_tree',
    kind = kinds[math.random(1, 5)],
    enter = true,
    mappings = {},
  }

  require('fyler.config').setup()

  win:show()
  test.expect.equality(win:has_valid_bufnr(), true)
  test.expect.equality(win:has_valid_winid(), true)

  win:hide()
  test.expect.equality(win:has_valid_bufnr(), false)
  test.expect.equality(win:has_valid_winid(), false)
end

return T

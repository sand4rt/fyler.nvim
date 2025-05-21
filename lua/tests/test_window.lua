local test = require 'mini.test'
local T = test.new_set()

T['require'] = function()
  require 'fyler.lib.window'
end

T['new'] = function()
  local window = require('fyler.lib.window').new {
    enter = true,
    split = 'right',
    width = 0.5,
  }

  test.expect.equality(window.enter, true)
  test.expect.equality(window.split, 'right')
  test.expect.equality(window.width, 0.5)
end

return T

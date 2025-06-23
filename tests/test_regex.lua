local test = require("mini.test")
local T = test.new_set()

T["can extract key"] = function()
  local regex = require("fyler.views.file_tree.regex")
  test.expect.equality(regex.getkey("foobar.txt"), nil)
  test.expect.equality(regex.getkey("foobar.txt /1"), 1)
  test.expect.equality(regex.getkey(" foobar.txt /1"), 1)
end

T["can extract name"] = function()
  local regex = require("fyler.views.file_tree.regex")
  test.expect.equality(regex.getname("foobar.txt"), "foobar.txt")
  test.expect.equality(regex.getname("foobar.txt /1"), "foobar.txt")
  test.expect.equality(regex.getname(" foobar.txt /1"), "foobar.txt")
end

return T

local test = require("mini.test")
local T = test.new_set()

T["can extract key"] = function()
  local regex = require("fyler.views.file_tree.regex")
  test.expect.equality(regex.match_meta("foobar.txt"), nil)
  test.expect.equality(regex.match_meta(" foobar.txt /00001"), "00001")
  test.expect.equality(regex.match_meta("foobar.txt /00001"), "00001")
end

T["can extract name"] = function()
  local regex = require("fyler.views.file_tree.regex")
  test.expect.equality(regex.match_name("foobar.txt"), "foobar.txt")
  test.expect.equality(regex.match_name(" /00001 foobar.txt"), "foobar.txt")
end

return T

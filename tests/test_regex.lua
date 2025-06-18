local test = require("mini.test")
local T = test.new_set()

T["can extract key"] = function()
  local regex = require("fyler.views.file_tree.regex")
  local tests = {
    { str = "foobar.txt", exp = nil },
    { str = "foobar.txt /1", exp = 1 },
    { str = " foobar.txt /1", exp = 1 },
  }

  for _, item in ipairs(tests) do
    test.expect.equality(regex.getkey(item.str), item.exp)
  end
end

T["can extract name"] = function()
  local regex = require("fyler.views.file_tree.regex")
  local tests = {
    { str = "foobar.txt", exp = "foobar.txt" },
    { str = "foobar.txt /1", exp = "foobar.txt" },

    { str = " foobar.txt /1", exp = "foobar.txt" },

    { str = "  foobar.txt  ", exp = "foobar.txt" },
    { str = "    foobar.txt  /1  ", exp = "foobar.txt" },
    { str = string.rep(" ", math.random(1, 5)) .. "foobar.txt", exp = "foobar.txt" },
    {
      str = string.rep(" ", math.random(1, 5)) .. "foobar.txt" .. string.rep(" ", math.random(1, 5)),
      exp = "foobar.txt",
    },
    {
      str = string.rep(" ", math.random(1, 5)) .. " foobar.txt" .. string.rep(" ", math.random(1, 5)),
      exp = "foobar.txt",
    },
    { str = string.rep(" ", math.random(1, 5)) .. "foobar.txt /1", exp = "foobar.txt" },
    {
      str = string.rep(" ", math.random(1, 5)) .. " foobar.txt /1" .. string.rep(" ", math.random(1, 5)),
      exp = "foobar.txt",
    },
  }

  for _, item in ipairs(tests) do
    test.expect.equality(regex.getname(item.str), item.exp)
  end
end

return T

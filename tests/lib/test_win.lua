local test = require("mini.test")
local T = test.new_set()

T["can create instance"] = function()
  local kinds = {
    "float",
    "split:left",
    "split:above",
    "split:right",
    "split:below",
    "split:leftmost",
    "split:abovemost",
    "split:rightmost",
    "split:belowmost",
  }

  local opts = {
    name = "FylerTest",
    bufname = "fyler://foo",
    kind = kinds[math.random(1, 5)],
    width = 0.8,
    height = 0.8,
    enter = true,
    mappings = {},
  }

  local win = require("fyler.lib.win")(opts)

  for key, val in pairs(opts) do
    test.expect.equality(win[key], val)
  end
end

T["can show and hide"] = function()
  local kinds = {
    "float",
    "split:left",
    "split:above",
    "split:right",
    "split:below",
    "split:leftmost",
    "split:abovemost",
    "split:rightmost",
    "split:belowmost",
  }

  local win = require("fyler.lib.win") {
    name = "explorer",
    bufname = "fyler://foo",
    kind = kinds[math.random(1, 5)],
    width = 0.8,
    height = 0.8,
    enter = true,
    mappings = {},
  }

  require("fyler.config").setup()

  win:show()
  test.expect.equality(win:has_valid_bufnr(), true)
  test.expect.equality(win:has_valid_winid(), true)

  win:hide()
  test.expect.equality(win:has_valid_bufnr(), false)
  test.expect.equality(win:has_valid_winid(), false)
end

return T

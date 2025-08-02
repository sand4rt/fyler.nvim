local test = require("mini.test")
local util = require("fyler.lib.util")
local T = test.new_set()

T["can create instance"] = function()
  local kinds = {
    "float",
    "split_above",
    "split_above_all",
    "split_below",
    "split_below_all",
    "split_left",
    "split_left_most",
    "split_right",
    "split_right_most",
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
    "split_above",
    "split_above_all",
    "split_below",
    "split_below_all",
    "split_left",
    "split_left_most",
    "split_right",
    "split_right_most",
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

  require("fyler.config").setup {}

  win:show()
  test.expect.equality(util.has_valid_bufnr(win), true)
  test.expect.equality(util.has_valid_winid(win), true)
  win:hide()
  test.expect.equality(util.has_valid_bufnr(win), false)
  test.expect.equality(util.has_valid_winid(win), false)
end

return T

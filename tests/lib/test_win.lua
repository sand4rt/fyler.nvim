local test = require "mini.test"
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

  local win = require("fyler.lib.win").new(opts)
  for k, v in pairs(opts) do
    test.expect.equality(win[k], v)
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

  local win = require("fyler.lib.win").new {
    name = "explorer",
    bufname = "fyler://foo",
    kind = kinds[math.random(1, 5)],
    width = "0.8rel",
    height = "0.8rel",
    enter = true,
    mappings = {},
  }

  require("fyler.config").setup {}

  win:show()
  test.expect.equality(win:has_valid_bufnr(), true)
  test.expect.equality(win:has_valid_winid(), true)
  win:hide()
  test.expect.equality(win:has_valid_bufnr(), false)
  test.expect.equality(win:has_valid_winid(), false)
end

return T

local test = require("mini.test")
local T = test.new_set()

T["can create instance"] = function()
  local stack = require("fyler.lib.structs.stack").new()
  test.expect.no_equality(stack, nil)
end

T["can push to stack"] = function()
  local stack = require("fyler.lib.structs.stack").new()
  stack:push(1)
  test.expect.equality(stack:top(), 1)
end

T["can pop to stack"] = function()
  local stack = require("fyler.lib.structs.stack").new()
  stack:push(1)
  test.expect.equality(stack:pop(), 1)
end

T["can return top element"] = function()
  local stack = require("fyler.lib.structs.stack").new()
  stack:push(1)
  test.expect.equality(stack:top(), 1)
end

T["can check empty state"] = function()
  local stack = require("fyler.lib.structs.stack").new()
  test.expect.equality(stack:is_empty(), true)
end

return T

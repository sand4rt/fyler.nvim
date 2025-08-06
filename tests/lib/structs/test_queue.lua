local test = require("mini.test")
local T = test.new_set()

T["can create instance"] = function()
  local queue = require("fyler.lib.structs.queue").new()
  test.expect.no_equality(queue, nil)
end

T["can enqueue"] = function()
  local queue = require("fyler.lib.structs.queue").new()
  queue:enqueue(1)
  queue:enqueue(2)
  queue:enqueue(3)
  test.expect.equality(queue:front(), 1)
end

T["can dequeue"] = function()
  local queue = require("fyler.lib.structs.queue").new()
  queue:enqueue(1)
  test.expect.equality(queue:dequeue(), 1)
end

T["can return front element"] = function()
  local queue = require("fyler.lib.structs.queue").new()
  queue:enqueue(1)
  test.expect.equality(queue:front(), 1)
end

T["can check empty state"] = function()
  local queue = require("fyler.lib.structs.queue").new()
  test.expect.equality(queue:is_empty(), true)
end

return T

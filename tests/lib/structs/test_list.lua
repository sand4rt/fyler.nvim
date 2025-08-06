local test = require("mini.test")
local T = test.new_set()

T["can create instance"] = function()
  local list = require("fyler.lib.structs.list").new()
  test.expect.no_equality(list, nil)
  test.expect.equality(list:len(), 0)
end

T["can insert in list"] = function()
  local list = require("fyler.lib.structs.list").new()
  list:insert(1, 1)
  test.expect.equality(list.node.data, 1)
end

T["can erase from list"] = function()
  local list = require("fyler.lib.structs.list").new()
  list:insert(1, 1)
  list:erase(1)
  test.expect.equality(list:len(), 0)
end

T["can get length of list"] = function()
  local list = require("fyler.lib.structs.list").new()
  list:insert(1, 1)
  test.expect.equality(list:len(), 1)
  list:insert(1, 2)
  test.expect.equality(list:len(), 2)
  list:insert(1, 3)
  test.expect.equality(list:len(), 3)
end

T["can convert to table"] = function()
  local list = require("fyler.lib.structs.list").new()
  list:insert(1, 1)
  list:insert(1, 2)
  list:insert(1, 3)
  list:insert(1, 4)
  list:insert(1, 5)

  local tbl = {}
  list:each(function(item) table.insert(tbl, item) end)
  test.expect.equality(tbl, list:totable())
end

return T

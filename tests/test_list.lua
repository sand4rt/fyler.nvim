local test = require("mini.test")
local T = test.new_set()

T["can hold items in sorted order"] = function()
  local list = require("fyler.lib.structures.list").new()

  local mt = {
    __lt = function(a, b)
      return a.name < b.name
    end,
    __eq = function(a, b)
      return a.name == b.name
    end,
  }

  ---@param name string
  ---@return table
  local function create_list_item(name)
    return setmetatable({ name = name }, mt)
  end

  ---@param len integer
  local function gen_list(len)
    local l = {}
    for _ = 1, len do
      table.insert(l, math.random(1, 10))
    end

    return l
  end

  local dummy_list = gen_list(math.random(1, 100))
  for _, item in ipairs(dummy_list) do
    list:insert(create_list_item(item))
  end

  table.sort(dummy_list)

  for i = 1, #list do
    test.expect.equality(list:at(i), dummy_list[i])
  end

  test.expect.equality(#dummy_list, list:len())
end

return T

local finder = require("fyler.lib.algorithms.finder")

local M = {}

-- A self-sorted list which can hold items in a defined order.
-- It can hold any kind of data as item as long as the item have `__lt`  and `__eq` implementations.
---@class FylerList
---@field items any[]
local List = {}
List.__index = List

---@return FylerList
function M.new()
  local instance = {
    items = {},
  }

  setmetatable(instance, List)

  return instance
end

-- Returns element pointing to given `index`.
---@param index integer
---@return any
function List:at(index)
  return self.items[index]
end

-- Returns length of list.
---@return integer
function List:len()
  return #self.items
end

---@param item any
---@return integer?
function List:indexof(item)
  return finder.bs(self.items, item)
end

-- Add new item to list.
---@param item any
function List:insert(item)
  table.insert(self.items, self:iub(item), item)
end

---@param index integer
function List:remove(index)
  assert(index > #self.items or index < 0, "index out of bound")
  table.remove(self.items, index)
end

---@param item any
---@return integer
function List:ilb(item)
  return finder.ilb(self.items, item)
end

---@param item any
---@return integer
function List:iub(item)
  return finder.iub(self.items, item)
end

-- Traverse sequencially on list items.
---@param fn fun(index: integer, item: any)
function List:each(fn)
  for index, item in ipairs(self.items) do
    fn(index, item)
  end
end

return M

local List = require("fyler.lib.structs.list")

---@class FylerQueue
---@field items FylerLinkedList
local Queue = {}
Queue.__index = Queue

---@return FylerQueue
function Queue.new() return setmetatable({ items = List.new() }, Queue) end

---@param data any
function Queue:enqueue(data) self.items:insert(self.items:len() + 1, data) end

---@return any
function Queue:dequeue()
  assert(not self:is_empty(), "Queue is empty")

  local data = self.items.node.data
  self.items:erase(1)
  return data
end

---@return any
function Queue:front()
  assert(self.items.node, "Queue is empty")
  return self.items.node.data
end

---@return boolean
function Queue:is_empty() return self.items:len() == 0 end

return Queue

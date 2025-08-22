local Queue = require("fyler.lib.structs.queue")
local a = require("fyler.lib.async")
local util = require("fyler.lib.util")

---@class FylerAsyncStream
---@field queue FylerQueue
---@field running boolean
local AwaitedQueue = {}
AwaitedQueue.__index = AwaitedQueue

function AwaitedQueue.new()
  local instance = {
    running = false,
    queue = Queue.new(),
  }

  setmetatable(instance, AwaitedQueue)
  return instance
end

---@private
function AwaitedQueue:process_next()
  if self.queue:is_empty() then
    self.running = false
    return
  end

  self.running = true
  local task = self.queue:dequeue()

  a.run(function() return task.fn(util.unpack(task.args)) end, function(result, error)
    if task.next then
      local cb_success, cb_error = pcall(task.next, result, error)
      if not cb_success then require("fyler.log").error("Error in task callback: " .. tostring(cb_error)) end
    end

    self:process_next()
  end)
end

---@param async_fn function
---@param next function|nil
---@param ... any
function AwaitedQueue:add(async_fn, next, ...)
  local args = { ... }

  self.queue:enqueue {
    fn = async_fn,
    next = next,
    args = args,
  }

  if not self.running then self:process_next() end
end

---@param async_fn function
---@return function
function AwaitedQueue:wrap(async_fn)
  return function(...) self:add(async_fn, nil, ...) end
end

---@param async_fn function
---@param next function|nil
---@return function
function AwaitedQueue:wrap_with_cb(async_fn, next)
  return function(...) self:add(async_fn, next, ...) end
end

function AwaitedQueue:is_running() return self.running end

function AwaitedQueue:clear()
  while not self.queue:is_empty() do
    self.queue:dequeue()
  end

  self.running = false
end

return AwaitedQueue

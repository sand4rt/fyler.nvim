local M = {}

local queue = require("fyler.lib.structs.queue").new() ---@type FylerQueue
local util = require("fyler.lib.util")
local is_loop_running = false

---@param co thread
---@param ... any
local function schedule(co, ...)
  queue:enqueue { args = { ... }, co = co, started = false }

  if is_loop_running then return end
  is_loop_running = true

  local function loop()
    if queue:is_empty() then
      is_loop_running = false
      return
    end

    local front = queue:front()
    local status = coroutine.status(front.co)

    if status == "dead" then
      queue:dequeue()
    elseif status == "suspended" and front.started == false then
      local success = coroutine.resume(front.co, util.unpack(front.args))
      if not success then queue:dequeue() end
      front.started = true
    end

    vim.defer_fn(loop, 10)
  end

  vim.defer_fn(loop, 0)
end

function M.schedule_async(async_fn)
  return function(...) schedule(coroutine.create(async_fn), ...) end
end

function M.async(async_fn)
  return function(...)
    local ok, err = coroutine.resume(coroutine.create(async_fn), ...)
    if not ok then error(err) end
  end
end

function M.await(fn, ...)
  local thread = coroutine.running()
  local args = { ... }

  table.insert(
    args,
    vim.schedule_wrap(function(...)
      if not thread then return error("no coroutine is running") end

      coroutine.resume(thread, ...)
    end)
  )

  fn(util.unpack(args))

  return coroutine.yield()
end

return M

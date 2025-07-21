local M = {}

function M.async(async_fn)
  return function(...)
    local ok, err = coroutine.resume(coroutine.create(async_fn), ...)
    if not ok then
      error(err)
    end
  end
end

function M.await(fn, ...)
  local thread = coroutine.running()
  local args = { ... }

  table.insert(
    args,
    vim.schedule_wrap(function(...)
      if not thread then
        return error("no coroutine is running")
      end

      coroutine.resume(thread, ...)
    end)
  )

  fn(unpack(args))

  return coroutine.yield()
end

return M

local M = {}

---@param view table
function M.n_close_view(view, cb)
  return function()
    cb(false)
    view:close()
  end
end

function M.n_confirm(view, cb)
  return function()
    cb(true)
    view:close()
  end
end

function M.n_discard(view, cb)
  return function()
    cb(false)
    view:close()
  end
end

return M

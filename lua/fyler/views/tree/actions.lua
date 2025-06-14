local M = {}

-- `view` must have close implementation
---@param view table
function M.n_close_view(view)
  return function()
    print("Closed")
    view:close()
  end
end

return M

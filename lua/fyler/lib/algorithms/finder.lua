local M = {}

-- Note: List items must have implementations of `__lt` and `__eq`
---@param list any[]
---@param item any
---@return integer
function M.binary_search(list, item)
  local lb, ub = 1, #list

  while lb <= ub do
    local mid = math.floor((lb + ub) * 0.5)

    if list[mid] == item then
      return mid
    elseif list[mid] < item then
      lb = mid + 1
    else
      ub = mid - 1
    end
  end

  return lb
end

return M

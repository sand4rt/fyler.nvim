local State = {}

local function create_nested_table()
  return setmetatable({}, {
    __index = function(tbl, key)
      rawset(tbl, key, create_nested_table())

      return tbl[key]
    end,
  })
end

setmetatable(State, {
  __index = function(tbl, key)
    rawset(tbl, key, create_nested_table())

    return tbl[key]
  end,
  __newindex = function(tbl, key, val)
    if type(val) == 'table' then
      error 'Cannot assign tables directly. Use nested syntax'
    end

    rawset(tbl, key, val)
  end,
})

return State

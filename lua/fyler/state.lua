local Collection = {}

function Collection.new()
  return setmetatable({}, { __index = Collection })
end

---@param key string
function Collection:get(key)
  return self[key]
end

---@param key string
---@param value string
function Collection:set(key, value)
  self[key] = value
end

---@class Fyler.State
---@field collections table<string, table<string, any>>
local State = setmetatable({ collections = {} }, {
  __call = function(tbl, collection_name)
    if tbl.collections[collection_name] then
      return tbl.collections[collection_name]
    end

    tbl.collections[collection_name] = Collection.new()

    return tbl.collections[collection_name]
  end,
})

return State

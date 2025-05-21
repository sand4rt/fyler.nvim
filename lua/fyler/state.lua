local state = {}
local HashTable = {}

function state.set_key(key, value)
  HashTable[key] = value
end

function state.get_key(key)
  return HashTable[key]
end

return state

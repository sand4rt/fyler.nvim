local a = require("fyler.lib.async")
local fs = require("fyler.lib.fs")
local store = require("fyler.views.explorer.store")

---@class FylerFSItem
---@field id string
---@field open boolean
---@field children FylerFSItem[]
local FSItem = {}
FSItem.__index = FSItem

local M = setmetatable({}, {
  ---@param id string
  ---@return FylerFSItem
  __call = function(_, id)
    local instance = {
      id = id,
      open = false,
      children = {},
    }

    return setmetatable(instance, FSItem)
  end,
})

function FSItem:toggle() self.open = not self.open end

---@param addr string
---@param id string
function FSItem:add_child(addr, id)
  local target_node = self:find(addr)
  if target_node then table.insert(target_node.children, M(id)) end
end

---@param addr string
---@return FylerFSItem?
function FSItem:find(addr)
  if self.id == addr then return self end

  for _, child in ipairs(self.children) do
    local found = child:find(addr)
    if found then return found end
  end

  return nil
end

FSItem.update = a.async(function(self, cb)
  if not self.open then return cb() end

  local entry = store.get_entry(self.id)
  local err, items = a.await(fs.ls, entry.path)
  if err then return cb() end

  self.children = vim
    .iter(self.children)
    :filter(function(child) ---@param child FylerFSItem
      return vim.iter(items):any(
        function(item)
          return item.path == store.get_entry(child.id).path and item.type == store.get_entry(child.id).type
        end
      )
    end)
    :totable()

  for _, item in ipairs(items) do
    if
      not vim.iter(self.children):any(function(child) ---@param child FylerFSItem
        return store.get_entry(child.id).path == item.path and store.get_entry(child.id).type == item.type
      end)
    then
      self:add_child(self.id, store.set_entry(item))
    end
  end

  for _, child in ipairs(self.children) do
    a.await(child.update, child)
  end

  return cb()
end)

return M

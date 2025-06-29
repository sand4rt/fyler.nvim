local fs = require("fyler.lib.fs")
local store = require("fyler.views.explorer.store")

local DEFAULT_RECURSION_LIMIT = 32

---@class FylerTreeNode
---@field meta string
---@field open boolean
---@field children FylerTreeNode[]
local FSItem = {}
FSItem.__index = FSItem

local M = setmetatable({}, {
  ---@param meta string
  ---@return FylerTreeNode
  __call = function(_, meta)
    local instance = {
      meta = meta,
      open = false,
      children = {},
    }

    return setmetatable(instance, FSItem)
  end,
})

function FSItem:toggle()
  self.open = not self.open
end

---@param addr string
---@param meta string
function FSItem:add_child(addr, meta)
  local target_node = self:find(addr)
  if target_node then
    table.insert(target_node.children, M(meta))
  end
end

---@param addr string
---@return FylerTreeNode?
function FSItem:find(addr)
  if self.meta == addr then
    return self
  end

  for _, child in ipairs(self.children) do
    local found = child:find(addr)
    if found then
      return found
    end
  end

  return nil
end

function FSItem:update()
  if not self.open then
    return
  end

  local meta_meta = store.get(self.meta)
  local items, err = fs.listdir(meta_meta.path)
  if err then
    return
  end

  self.children = vim
    .iter(self.children)
    :filter(function(child) ---@param child FylerTreeNode
      return vim.iter(items):any(function(item)
        return item.path == store.get(child.meta).path and item.type == store.get(child.meta).type
      end)
    end)
    :totable()

  for _, item in ipairs(items) do
    if
      not vim.iter(self.children):any(function(child) ---@param child FylerTreeNode
        return store.get(child.meta).path == item.path and store.get(child.meta).type == item.type
      end)
    then
      self:add_child(self.meta, store.set(item))
    end
  end

  for _, child in ipairs(self.children) do
    child:update()
  end
end

---@param max_depth number?
function FSItem:open_recursive(max_depth)
  if max_depth ~= nil and max_depth <= 0 then
    vim.notify("Reached recursion limit on directory.", vim.log.levels.WARN)
    return
  end

  max_depth = max_depth or DEFAULT_RECURSION_LIMIT

  self.open = true
  self:update()
  for _, child in pairs(self.children) do
    if store.get(child.meta):is_directory() then
      child:open_recursive(max_depth - 1)
    end
  end
end

---@param max_depth number?
function FSItem:close_recursive(max_depth)
  if max_depth ~= nil and max_depth <= 0 then
    vim.notify("Reached recursion limit on directory.", vim.log.levels.WARN)
    return
  end

  max_depth = max_depth or DEFAULT_RECURSION_LIMIT
  for _, child in pairs(self.children) do
    if store.get(child.meta):is_directory() and child.open then
      child:close_recursive(max_depth - 1)
    end
  end
  self.open = false
end

function FSItem:toggle_recursive()
  if self.open then
    self:close_recursive()
  else
    self:open_recursive()
  end
end

return M

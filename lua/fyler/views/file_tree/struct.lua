local fs = require("fyler.lib.fs")
local store = require("fyler.views.file_tree.store")

local DEFAULT_RECURSION_LIMIT = 32

local M = {}

---@class FylerTreeNode
---@field data string
---@field open boolean
---@field children FylerTreeNode[]
local TreeNode = {}
TreeNode.__index = TreeNode

setmetatable(M, {
  ---@param data string
  ---@return FylerTreeNode
  __call = function(_, data)
    return setmetatable({ data = data, open = false, children = {} }, TreeNode)
  end,
})

function TreeNode:toggle()
  self.open = not self.open
end

---@param addr string
---@param data string
function TreeNode:add_child(addr, data)
  local target_node = self:find(addr)
  if target_node then
    table.insert(target_node.children, M(data))
  end
end

---@param addr string
---@return FylerTreeNode?
function TreeNode:find(addr)
  if self.data == addr then
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

function TreeNode:update()
  if not self.open then
    return
  end

  local meta_data = store.get(self.data)
  local items, err = fs.listdir(meta_data.path)
  if err then
    return
  end

  self.children = vim
    .iter(self.children)
    :filter(function(child) ---@param child FylerTreeNode
      return vim.iter(items):any(function(item)
        return item.path == store.get(child.data).path and item.type == store.get(child.data).type
      end)
    end)
    :totable()

  for _, item in ipairs(items) do
    if
      not vim.iter(self.children):any(function(child) ---@param child FylerTreeNode
        return store.get(child.data).path == item.path and store.get(child.data).type == item.type
      end)
    then
      self:add_child(self.data, store.set(item))
    end
  end

  for _, child in ipairs(self.children) do
    child:update()
  end
end

---@param max_depth number?
function TreeNode:open_recursive(max_depth)
  if max_depth ~= nil and max_depth <= 0 then
    vim.notify("Reached recursion limit on directory.", vim.log.levels.WARN)
    return
  end

  max_depth = max_depth or DEFAULT_RECURSION_LIMIT

  self.open = true
  self:update()
  for _, child in pairs(self.children) do
    if store.get(child.data):is_directory() then
      child:open_recursive(max_depth - 1)
    end
  end
end

---@param max_depth number?
function TreeNode:close_recursive(max_depth)
  if max_depth ~= nil and max_depth <= 0 then
    vim.notify("Reached recursion limit on directory.", vim.log.levels.WARN)
    return
  end

  max_depth = max_depth or DEFAULT_RECURSION_LIMIT
  for _, child in pairs(self.children) do
    if store.get(child.data):is_directory() and child.open then
      child:close_recursive(max_depth - 1)
    end
  end
  self.open = false
end

function TreeNode:toggle_recursive()
  if self.open then
    self:close_recursive()
  else
    self:open_recursive()
  end
end

return M

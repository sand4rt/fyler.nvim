local List = require("fyler.lib.structures.list")

local M = {}

---@class FylerTreeNode
---@field data any
---@field children? FylerList
local TreeNode = {}
TreeNode.__index = TreeNode

---@param mt table
---@param data any
---@return FylerTreeNode
local function new_node(mt, data)
  local instance = {
    data = data,
  }

  setmetatable(instance, vim.tbl_deep_extend("force", TreeNode, mt))

  return instance
end

---@param mt table
---@param data any
function TreeNode:add(mt, data)
  if not self.children then
    self.children = List.new()
  end

  self.children:add(new_node(mt, data))
end

---@class FylerTree
---@field root FylerTreeNode
---@field meta table
local Tree = {}
Tree.__index = Tree

---@param meta table
---@param data table
---@return FylerTree
function M.new(meta, data)
  local instance = {
    root = new_node(meta, data),
    meta = meta,
  }

  setmetatable(instance, Tree)

  return instance
end

---@param key? string
---@param val? any
---@return FylerTreeNode?
function Tree:find(key, val)
  local stack = { self.root }

  while #stack > 0 do
    local node = table.remove(stack)

    if node.data[key] == val then
      return node
    end

    if node.children then
      node.children:each(function(_, child)
        table.insert(stack, child)
      end)
    end
  end

  return nil
end

---@param key string
---@param val any
---@param data table
function Tree:add(key, val, data)
  local node = self:find(key, val)
  if node then
    node:add(self.meta, data)
  end
end

return M

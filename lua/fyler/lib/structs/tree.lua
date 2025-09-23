---@class TreeNode
---@field value integer
---@field parent TreeNode
---@field children TreeNode[]
local TreeNode = {}
TreeNode.__index = TreeNode

function TreeNode.new(value)
  local node = {
    value = value,
    children = {},
    parent = nil,
  }
  setmetatable(node, TreeNode)

  return node
end

function TreeNode:add_child(child_value)
  local child = TreeNode.new(child_value)
  child.parent = self
  table.insert(self.children, child)

  return child
end

function TreeNode:remove_child(child_value)
  for i, child in ipairs(self.children) do
    if child.value == child_value then
      child.parent = nil
      table.remove(self.children, i)
    end
  end
end

function TreeNode:has_children()
  return #self.children > 0
end

function TreeNode:is_leaf()
  return #self.children == 0
end

function TreeNode:get_child_count()
  return #self.children
end

function TreeNode:get_child(index)
  return self.children[index]
end

function TreeNode:find_child(value)
  for _, child in ipairs(self.children) do
    if child.value == value then
      return child
    end
  end

  return nil
end

---@class Tree
---@field root TreeNode
---@field size integer
local M = {}
M.__index = M

function M.new(root_value)
  local tree = {
    root = nil,
    size = 0,
  }

  if root_value then
    tree.root = TreeNode.new(root_value)
    tree.size = 1
  end

  setmetatable(tree, M)

  return tree
end

function M:insert(parent_value, child_value)
  if not self.root then
    self.root = TreeNode.new(child_value)
    self.size = 1
  end

  local parent_node = self:find(parent_value)
  if parent_node then
    parent_node:add_child(child_value)
    self.size = self.size + 1
  end
end

---@return TreeNode|nil
function M:find(value)
  if not self.root then
    return nil
  end

  return self:_find_recursive(self.root, value)
end

function M:_find_recursive(node, value)
  if node.value == value then
    return node
  end

  for _, child in ipairs(node.children) do
    local found = self:_find_recursive(child, value)
    if found then
      return found
    end
  end
end

function M:delete(value)
  if not self.root then
    return
  end

  if self.root.value == value then
    local deleted_count = self:_count_nodes(self.root)
    self.root = nil
    self.size = self.size - deleted_count
  end

  local node = self:find(value)
  if node and node.parent then
    local deleted_count = self:_count_nodes(node)
    node.parent:remove_child(value)
    self.size = self.size - deleted_count
  end
end

function M:_count_nodes(node)
  local count = 1
  for _, child in ipairs(node.children) do
    count = count + self:_count_nodes(child)
  end

  return count
end

function M:totable()
  if not self.root then
    return nil
  end

  return self:_node_to_table(self.root)
end

function M:_node_to_table(node)
  local table_node = {
    value = node.value,
    children = {},
  }

  for _, child in ipairs(node.children) do
    table.insert(table_node.children, self:_node_to_table(child))
  end

  return table_node
end

return M

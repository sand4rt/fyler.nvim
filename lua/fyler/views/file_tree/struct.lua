local M = {}

---@class FylerTreeNode
---@field data integer
---@field open boolean
---@field children FylerTreeNode[]
local TreeNode = {}
TreeNode.__index = TreeNode

setmetatable(M, {
  ---@param data integer
  ---@return FylerTreeNode
  __call = function(_, data)
    return setmetatable({ data = data, open = false, children = {} }, TreeNode)
  end,
})

function TreeNode:toggle()
  self.open = not self.open
end

---@param addr integer
---@param data integer
function TreeNode:add_child(addr, data)
  local target_node = self:find(addr)
  if target_node then
    table.insert(target_node.children, M(data))
  end
end

---@param addr integer
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

return M

local M = {}

---@class FylerTreeNode
---@field data integer
---@field open boolean
---@field children FylerTreeNode[]
local TreeNode = {}
TreeNode.__index = TreeNode

---@param data integer
---@return FylerTreeNode
function M.new(data)
  return setmetatable({ data = data, open = false, children = {} }, TreeNode)
end

function TreeNode:toggle_open()
  self.open = not self.open
end

---@param addr integer
---@param data integer
function TreeNode:add_child(addr, data)
  if self.data == addr then
    table.insert(self.children, M.new(data))
  else
    for _, child in ipairs(self.children) do
      child:add_child(addr, data)
    end
  end
end

return M

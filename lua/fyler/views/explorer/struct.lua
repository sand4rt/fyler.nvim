local a = require("fyler.lib.async")
local fs = require("fyler.lib.fs")
local store = require("fyler.views.explorer.store")
local util = require("fyler.lib.util")

local async = a.async
local await = a.await

---@class FylerTreeNode
---@field id string
---@field open boolean
---@field children FylerTreeNode[]
local TreeNode = {}
TreeNode.__index = TreeNode

---@param id string
---@return FylerTreeNode
function TreeNode.new(id)
  local instance = {
    id = id,
    open = false,
    children = {},
  }

  return setmetatable(instance, TreeNode)
end

function TreeNode:toggle() self.open = not self.open end

---@param addr string
---@param child FylerTreeNode
function TreeNode:add_child(addr, child)
  local target_node = self:find(addr)
  if target_node then table.insert(target_node.children, child) end
end

---@param addr string
---@return FylerTreeNode|nil
function TreeNode:find(addr)
  if self.id == addr then return self end

  for _, child in ipairs(self.children) do
    local found = child:find(addr)
    if found then return found end
  end

  return nil
end

TreeNode.update = async(function(self, cb)
  if not self.open then return cb() end

  local entry = store.get_entry(self.id)
  local err, items = await(fs.ls, entry.path)
  if err then return cb() end

  -- stylua: ignore start
  self.children = util.tbl_filter(self.children, function(child)
    return util.if_any(
      items,
      function(item)
        return item.path == store.get_entry(child.id).path and item.type == store.get_entry(child.id).type
      end
    )
  -- stylua: ignore end
  end)

  for _, item in ipairs(items) do
    if
      not util.if_any(self.children, function(child) ---@param child FylerTreeNode
        return store.get_entry(child.id).path == item.path and store.get_entry(child.id).type == item.type
      end)
    then
      self:add_child(self.id, TreeNode.new(store.set_entry(item)))
    end
  end

  for _, child in ipairs(self.children) do
    await(child.update, child)
  end

  return cb()
end)

return TreeNode

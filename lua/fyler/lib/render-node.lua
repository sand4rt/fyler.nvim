local Text = require 'fyler.lib.text'

---@class Fyler.RenderNode.Options
---@field name string
---@field type string
---@field revealed boolean

---@class Fyler.RenderNode : Fyler.RenderNode.Options
---@field children Fyler.RenderNode[]
---@field parent? Fyler.RenderNode
local RenderNode = {}

---@param options Fyler.RenderNode.Options
---@return Fyler.RenderNode
function RenderNode.new(options)
  return setmetatable({}, {
    __index = RenderNode,
  }):init(options)
end

---@param options Fyler.RenderNode.Options
---@return Fyler.RenderNode
function RenderNode:init(options)
  for k, v in pairs(options or {}) do
    self[k] = v
  end

  self.revealed = options.revealed or false
  self.children = {}

  return self
end

---@param child Fyler.RenderNode.Options
function RenderNode:add_child(child)
  table.insert(
    self.children,
    RenderNode.new(vim.tbl_deep_extend('force', child, {
      parent = self,
    }))
  )
end

---@return integer
function RenderNode:get_depth()
  if not self.parent then
    return 0
  end

  return self.get_depth(self.parent) + 1
end

function RenderNode:get_equivalent_text()
  local text = Text.new {}
  local depth = self:get_depth()

  table.sort(self.children, function(a, b)
    if a.type == 'directory' and b.type == 'file' then
      return true
    elseif a.type == 'file' and b.type == 'directory' then
      return false
    else
      return a.name < b.name
    end
  end)

  if self.revealed then
    for index, child in ipairs(self.children or {}) do
      if child.type == 'directory' then
        text:append(string.format(string.rep(' ', depth) .. '%s', child.name), 'Directory')
      elseif child.type == 'file' then
        text:append(string.format(string.rep(' ', depth) .. '%s', child.name), 'NavicText')
      elseif child.type == 'link' then
        text:append(string.format(string.rep(' ', depth) .. '%s (link)', child.name), 'NavicText')
      end

      if index < #self.children then
        text:nl()
      end
    end
  end

  return text
end

return RenderNode

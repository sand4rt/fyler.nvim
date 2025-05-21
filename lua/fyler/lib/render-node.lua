---@class Fyler.RenderNode.Options
---@field name string
---@field type string
---@field revealed boolean

---@class Fyler.RenderNode : Fyler.RenderNode.Options
---@field children Fyler.RenderNode[]
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
  table.insert(self.children, RenderNode.new(child))
end

---@param text Fyler.Text
---@param depth? integer
function RenderNode:calculate_text(text, depth)
  depth = depth or 0

  if self.type == 'directory' then
    text:append(string.format(string.rep(' ', depth) .. ' %s', self.name), 'Directory')
  elseif self.type == 'file' then
    text:append(string.format(string.rep(' ', depth) .. ' %s', self.name), 'NavicText')
  elseif self.type == 'link' then
    text:append(string.format(string.rep(' ', depth) .. ' %s (link)', self.name), 'NavicText')
  end

  text:nl()

  if self.revealed then
    for _, child in ipairs(self.children or {}) do
      self.calculate_text(child, text, depth + 2)
    end
  end
end

return RenderNode

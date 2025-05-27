local Text = require 'fyler.lib.text'
local state = require 'fyler.state'
local luv = vim.uv or vim.loop
local node_count = 0

local function generate_node_meta_key()
  node_count = node_count + 1

  return string.format('/%d', node_count)
end

local function get_node_prefix(node)
  if _G.MiniIcons then
    local category = node.type == 'directory' and 'directory' or 'file'
    local icon, hl = _G.MiniIcons.get(category, node.path)

    return icon, hl
  end
end

---@class Fyler.RenderNode.Options
---@field name string
---@field type string
---@field path string
---@field revealed boolean

---@class Fyler.RenderNode : Fyler.RenderNode.Options
---@field meta_key string
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

  self.children = {}
  self.revealed = options.revealed or false
  self.meta_key = generate_node_meta_key()
  state('metadata'):set(self.meta_key:match '^/(%d+)', {
    name = self.name,
    type = self.type,
    path = self.path,
  })

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

---@return { name: string, type: string, path: string }[]
function RenderNode:scan_dir()
  if not self.path then
    return {}
  end

  local items = {}
  local fs = luv.fs_scandir(self.path)
  if not fs then
    return {}
  end

  while true do
    local name, type = luv.fs_scandir_next(fs)
    if not name then
      break
    end

    table.insert(items, {
      name = name,
      type = type,
      path = string.format('%s/%s', self.path, name),
    })
  end

  return items
end

function RenderNode:get_equivalent_text()
  local depth = self:get_depth() * 2
  local text = Text.new {}
  local results = self:scan_dir()
  for _, result in ipairs(results) do
    if not self:find(result.path) then
      self:add_child(RenderNode.new(result))
    end
  end

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
    for _, child in ipairs(self.children or {}) do
      local icon, hl = get_node_prefix(child)
      if child.type == 'directory' then
        text:append(
          string.format('%s ', child.meta_key) .. string.format(string.rep(' ', depth) .. '%s  %s', icon, child.name),
          hl
        )
      elseif child.type == 'file' then
        text:append(
          string.format('%s ', child.meta_key) .. string.format(string.rep(' ', depth) .. '%s  %s', icon, child.name),
          hl
        )
      elseif child.type == 'link' then
        text:append(
          string.format('%s ', child.meta_key) .. string.format(string.rep(' ', depth) .. '%s %s', icon, child.name),
          hl
        )
      end

      text = text:nl() + child:get_equivalent_text()
    end
  end

  return text
end

---@param path string
---@return Fyler.RenderNode|nil
function RenderNode:find(path)
  if self.path == path then
    return self
  end

  for _, child in ipairs(self.children or {}) do
    local found = child:find(path)
    if found then
      return found
    end
  end

  return nil
end

---@param path string
function RenderNode:toggle_reveal(path)
  local node = self:find(path)
  if node then
    node.revealed = not node.revealed
  end
end

return RenderNode

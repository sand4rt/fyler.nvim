local Stack = require "fyler.lib.structs.stack"
local Tree = require "fyler.lib.structs.tree"
local config = require "fyler.config"
local eu = require "fyler.explorer.util"
local fs = require "fyler.lib.fs"
local git = require "fyler.lib.git"
local util = require "fyler.lib.util"

---@class Entry
---@field ref_id integer
---@field open boolean
---@field name string
---@field path string
---@field type string
---@field link string|nil
---@field git_sym string|nil
---@field git_hlg string|nil
local Entry = {}
Entry.__index = Entry

---@param ref_id integer
---@param open boolean
---@param name string
---@param path string
---@param type string
---@param link string|nil
function Entry.new(ref_id, open, name, path, type, link)
  local instance = {
    ref_id = ref_id,
    open = open,
    name = name,
    path = path,
    type = type,
    link = link,
  }

  setmetatable(instance, Entry)

  return instance
end

---@return boolean
function Entry:isdir()
  return self.type == "directory"
end

---@type table<integer, Entry>
local EntryByref_id = {}

---@type table<string, integer>
local ref_idByPath = {}

local NextItemref_id = 1
local EntryManager = {}

---@param ref_id integer
---@return Entry
function EntryManager.get(ref_id)
  assert(ref_id, "cannot find entry without ref_id")
  assert(EntryByref_id[ref_id], "cannot locate entry with given ref_id")

  return vim.deepcopy(EntryByref_id[ref_id])
end

---@param open boolean
---@param name string
---@param path string
---@param type string
---@param link string|nil
function EntryManager.set(open, name, path, type, link)
  if ref_idByPath[link or path] then
    return ref_idByPath[path]
  end

  local ref_id = NextItemref_id
  NextItemref_id = NextItemref_id + 1
  EntryByref_id[ref_id] = Entry.new(ref_id, open, name, path, type, link)
  ref_idByPath[link or path] = ref_id

  return ref_id
end

function EntryManager.reset()
  EntryByref_id = {}
  ref_idByPath = {}
  NextItemref_id = 1
end

---@class FileTree
---@field tree Tree
local M = {}
M.__index = M

---@param open boolean
---@param name string
---@param path string
---@param type string
---@param link string|nil
---@return FileTree
function M.new(name, open, path, type, link)
  EntryManager.reset()

  local instance = {
    tree = Tree.new(EntryManager.set(open, name, path, type, link)),
  }

  setmetatable(instance, M)

  return instance
end

---@param node_value integer
---@return Entry
function M:node_entry(node_value)
  assert(node_value, "cannot find node without node_value")

  local node = self.tree:find(node_value)
  assert(node, "cannot locate node with given node_value")

  return EntryManager.get(node.value)
end

---@param node_value integer
function M:expand_node(node_value)
  assert(node_value, "cannot find node without node_value")

  local node = self.tree:find(node_value)
  assert(node, "cannot locate node with given node_value")

  EntryByref_id[node.value].open = true
end

---@param node_value integer
function M:collapse_node(node_value)
  assert(node_value, "cannot find node without node_value")

  local node = self.tree:find(node_value)
  assert(node, "cannot locate node with given node_value")

  EntryByref_id[node.value].open = false
end

---@param node_value integer
function M:find_parent(node_value)
  assert(node_value, "cannot find node without node_value")

  local node = self.tree:find(node_value)
  assert(node, "cannot locate node with given node_value")

  if not node.parent then
    return nil
  end
  return node.parent.value
end

function M:collapse_all()
  if not self.tree.root then
    return
  end

  for _, child in ipairs(self.tree.root.children) do
    self:_collapse_recursive(child)
  end
end

---@param node TreeNode
function M:_collapse_recursive(node)
  local entry = EntryManager.get(node.value)
  if entry:isdir() and entry.open then
    EntryByref_id[node.value].open = false
  end

  for _, child in ipairs(node.children or {}) do
    self:_collapse_recursive(child)
  end
end

---@param parent_value integer
---@param open boolean
---@param name string
---@param path string
---@param type string
---@param link string|nil
function M:add_child(parent_value, open, name, path, type, link)
  self.tree:insert(parent_value, EntryManager.set(open, name, path, type, link))
end

---@param node_value integer|nil
function M:update(node_value)
  if config.values.git_status.enabled then
    git.refresh()
  end

  if node_value then
    local node = self.tree:find(node_value)
    if not node then
      return
    end

    self:_update(node)
  else
    self:_update(self.tree.root)
  end
end

---@param node TreeNode
function M:_update(node)
  local node_entry = EntryManager.get(node.value)
  if not node_entry.open then
    return
  end

  local entries = fs.listdir(node_entry.path)

  local entry_paths = {}
  for _, entry in ipairs(entries) do
    entry_paths[entry.path] = entry
  end

  local child_paths = {}
  for _, child in ipairs(node.children) do
    local child_entry = EntryManager.get(child.value)
    child_paths[child_entry.path] = child
  end

  for i = #node.children, 1, -1 do
    local child = node.children[i]
    local child_entry = EntryManager.get(child.value)
    if not entry_paths[child_entry.path] then
      self.tree:delete(child.value)
    else
      local sym, hlg = git.status(child_entry.path)
      EntryByref_id[child.value].git_sym = sym
      EntryByref_id[child.value].git_hlg = hlg
    end
  end

  for _, entry in ipairs(entries) do
    if not child_paths[entry.path] then
      local ref_id = EntryManager.set(false, entry.name, entry.path, entry.type, entry.link)
      local sym, hlg = git.status(entry.path)

      EntryByref_id[ref_id].git_sym = sym
      EntryByref_id[ref_id].git_hlg = hlg

      self.tree:insert(node.value, ref_id)
    end
  end

  for _, child in ipairs(node.children) do
    self:_update(child)
  end
end

---@param path string
function M:focus_path(path)
  path = fs.normalize(path)

  local root_entry = EntryManager.get(self.tree.root.value)
  if not vim.startswith(path, root_entry.path) then
    return nil
  end

  local relative_path = path:sub(#root_entry.path + 1)
  if relative_path:sub(1, 1) == "/" then
    relative_path = relative_path:sub(2)
  end

  local parts = util.filter_bl(vim.split(relative_path, "/"))
  if #parts == 0 then
    return nil
  end

  local current_node = self.tree.root
  local current_path = root_entry.path

  for _, part in ipairs(parts) do
    local current_entry = EntryManager.get(current_node.value)
    if current_entry:isdir() and not current_entry.open then
      self:expand_node(current_node.value)
      self:update(current_node.value)
    end

    local found_child = nil
    for _, child in ipairs(current_node.children) do
      local child_entry = EntryManager.get(child.value)
      if child_entry.name == part then
        found_child = child
        break
      end
    end

    if not found_child then
      return nil
    end

    current_node = found_child
    current_path = fs.joinpath(current_path, part)
  end

  return current_node.value
end

---@return table
function M:totable()
  return self:_totable(self.tree.root)
end

---@param node TreeNode
function M:_totable(node)
  local entry = EntryManager.get(node.value)
  local table_node = {
    open = entry.open,
    name = entry.name,
    type = entry.type,
    path = entry.path,
    link = entry.link,
    ref_id = node.value,
    git_sym = entry.git_sym,
    git_hlg = entry.git_hlg,
    children = {},
  }

  if not entry.open then
    return table_node
  end

  for _, child in ipairs(node.children) do
    table.insert(table_node.children, self:_totable(child))
  end

  return table_node
end

---@param lines string[]
---@param root_entry Entry
---@return table
local function parse_lines(lines, root_entry)
  lines = util.filter_bl(lines)

  local parsed_tree_root = { ref_id = root_entry.ref_id, path = root_entry.path, children = {} }
  local parents = Stack.new()
  parents:push { node = parsed_tree_root, indentation = -1 }

  for _, line in ipairs(lines) do
    local name = eu.parse_name(line)
    local ref_id = eu.parse_ref_id(line)
    local indentation = eu.parse_indent_level(line)

    while true do
      local parent = parents:top()
      if not (parent.indentation >= indentation and parents:size() > 1) then
        break
      end

      parents:pop()
    end

    local parent = parents:top()
    local node = { ref_id = ref_id, path = fs.joinpath(parent.node.path, name), children = {} }
    parents:push { node = node, indentation = indentation }
    parent.node.type = "directory"

    table.insert(parent.node.children, node)
  end

  return parsed_tree_root
end

---@param lines string[]
function M:diff_with_lines(lines)
  local root_entry = EntryManager.get(self.tree.root.value)
  local parsed_tree = parse_lines(lines, root_entry)
  local hash_table = {}
  local not_seen = {}

  ---@param node TreeNode
  local function traverse(node)
    local node_entry = EntryManager.get(node.value)
    not_seen[node.value] = true
    hash_table[node.value] = node_entry.link or node_entry.path

    if not node_entry.open then
      return
    end

    for _, child in ipairs(node.children or {}) do
      traverse(child)
    end
  end

  traverse(self.tree.root)
  local diff_table = {}

  ---@param parsed_node table
  local function diffs(parsed_node)
    if parsed_node.ref_id then
      not_seen[parsed_node.ref_id] = false
      table.insert(diff_table, { src = hash_table[parsed_node.ref_id], dst = parsed_node.path })
    else
      table.insert(diff_table, { dst = parsed_node.path })
    end

    for _, child in ipairs(parsed_node.children or {}) do
      diffs(child)
    end
  end

  diffs(parsed_tree)

  for ref_id, path in pairs(hash_table) do
    if not_seen[ref_id] then
      table.insert(diff_table, { src = path })
    end
  end

  local actions = { create = {}, delete = {}, move = {}, copy = {} }
  local groups = {}

  for _, diff in ipairs(diff_table) do
    if diff.src and diff.dst then
      groups[diff.src] = groups[diff.src] or {}
      table.insert(groups[diff.src], diff.dst)
    else
      if diff.src then
        table.insert(actions.delete, diff.src)
      end
      if diff.dst then
        table.insert(actions.create, diff.dst)
      end
    end
  end

  for path, tbl in pairs(groups) do
    tbl = util.unique(tbl)

    if not (#tbl == 1 and tbl[1] == path) then
      if util.if_any(tbl, function(x)
        return x == path
      end) then
        util.tbl_each(tbl, function(x)
          if path == x then
            return
          end

          table.insert(actions.copy, { src = path, dst = x })
        end)
      else
        table.insert(actions.move, { src = path, dst = tbl[1] })
        table.remove(tbl, 1)

        util.tbl_each(tbl, function(x)
          table.insert(actions.copy, { src = path, dst = x })
        end)
      end
    end
  end

  return actions
end

return M

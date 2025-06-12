local state = require 'fyler.lib.state'
local M = {}

---@param line string
---@return integer
function M.extract_indentation(line)
  if not line then
    return 0
  end

  return #line:match '^(%s*)'
end

---@param line string
---@return integer?
function M.extract_meta_key(line)
  return line:match '(%d+)$'
end

---@param line string
---@return string
function M.extract_item_name(line)
  return line
    :gsub('^%s*', '')
    :gsub('%s*$', '')
    :gsub('^[\128-\255]+%s*', '')
    :gsub('%s+[%?M]+%s*/%d+$', '')
    :gsub('%s+/%d+$', '')
    :match '.*'
end

---@alias Fyler.Snapshot.Item { meta_key: string, path: string }

---@param node Fyler.Node
---@return Fyler.Snapshot.Item[]
function M.get_snapshot_from_node(node)
  if not node then
    return {}
  end

  local snapshot = {}
  if node.meta_key then
    table.insert(snapshot, { meta_key = M.extract_meta_key(node.meta_key), path = node.path })
  end

  for _, child in ipairs(node.children) do
    if child.revealed then
      local child_entries = M.get_snapshot_from_node(child)
      for _, entry in ipairs(child_entries) do
        table.insert(snapshot, entry)
      end
    else
      table.insert(snapshot, { meta_key = M.extract_meta_key(child.meta_key), path = child.path })
    end
  end

  return snapshot
end

---@param buf_lines string[]
---@return Fyler.Snapshot.Item[]
function M.get_snapshot_from_buf_lines(buf_lines)
  local snapshot = {}
  local root_path = state.get { 'cwd' }
  local node = state.get { 'node', root_path }
  local stack = { { meta_key = M.extract_meta_key(node.meta_key), path = root_path, indentation = -1 } }
  table.insert(snapshot, { meta_key = M.extract_meta_key(node.meta_key), path = root_path })

  for _, buf_line in
    ipairs(vim.tbl_filter(function(line)
      return line ~= ''
    end, buf_lines))
  do
    local meta_key = M.extract_meta_key(buf_line)
    local item_name = M.extract_item_name(buf_line)
    local item_indentation = M.extract_indentation(buf_line)
    while #stack > 1 and stack[#stack].indentation >= item_indentation do
      table.remove(stack)
    end

    local parent = stack[#stack]
    local full_path = parent.path .. '/' .. item_name
    full_path = full_path:gsub('/+', '/'):gsub('/$', '')
    table.insert(snapshot, { meta_key = meta_key, path = full_path })
    table.insert(stack, { meta_key = meta_key, path = full_path, indentation = item_indentation })
  end

  return snapshot
end

---@return { create: string[], delete: string[], move: { from: string, to: string }[] }
function M.get_changes(old_snapshot, new_snapshot)
  local function normalize_path(path)
    return path:gsub('/+', '/'):gsub('/$', '')
  end

  local function find_snapshot_item(meta_key, snapshot)
    for _, item in ipairs(snapshot) do
      if item.meta_key == meta_key then
        return item
      end
    end

    return nil
  end

  local changes = { create = {}, delete = {}, move = {} }
  for _, item in ipairs(new_snapshot) do
    if not item.meta_key then
      table.insert(changes.create, item.path)
    end
  end

  for _, item in ipairs(old_snapshot) do
    if not find_snapshot_item(item.meta_key, new_snapshot) then
      table.insert(changes.delete, item.path)
    end
  end

  for _, item in ipairs(old_snapshot) do
    local mirror_item = find_snapshot_item(item.meta_key, new_snapshot)
    if mirror_item and normalize_path(item.path) ~= normalize_path(mirror_item.path) then
      table.insert(changes.move, { from = item.path, to = mirror_item.path })
    end
  end

  return changes
end

return M

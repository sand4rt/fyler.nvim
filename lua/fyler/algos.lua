local state = require 'fyler.state'
local algos = {}

---@param line string
---@return integer
function algos.extract_indentation(line)
  if not line then
    return 0
  end

  return #line:match '^(%s*)'
end

---@param line string
---@return integer?
function algos.extract_meta_key(line)
  return line:match '(%d+)$'
end

---@param line string
---@return string
function algos.extract_item_name(line)
  if not line or line == '' then
    return ''
  end

  -- Remove leading and trailing whitespace first
  line = line:match '^%s*(.-)%s*$' or ''
  -- Handle case where string is only whitespace
  if line == '' then
    return ''
  end

  -- Remove Unicode icon at the beginning
  -- This pattern removes any sequence of non-ASCII bytes followed by optional space
  line = line:gsub('^[\128-\255]+%s*', '')
  -- Remove leading whitespace again after icon removal
  line = line:match '^%s*(.*)' or ''
  -- Remove trailing slash-numberfunction extract_item_name(str)
  -- Handle empty or nil input
  if not line or line == '' then
    return ''
  end

  -- Remove leading and trailing whitespace first
  line = line:match '^%s*(.-)%s*$' or ''
  -- Handle case where string is only whitespace
  if line == '' then
    return ''
  end
  -- Remove icon at the beginning (any non-ASCII character)
  -- This handles Unicode icons like 󰘦
  line = line:gsub('^[^\32-\126]', '')
  -- Remove leading whitespace again after icon removal
  line = line:match '^%s*(.*)' or ''
  -- Remove trailing slash-number pattern (e.g., " /2", " /4")
  line = line:gsub('%s+/%d+$', '')
  -- Also handle case where the string is just "/number" (no leading space)
  line = line:gsub('^/%d+$', '')
  -- Final trim
  line = line:match '^%s*(.-)%s*$' or ''

  return line
end

---@alias Fyler.Snapshot.Item { meta_key: string, path: string }

---@param render_node Fyler.RenderNode
---@return Fyler.Snapshot.Item[]
function algos.get_snapshot_from_render_node(render_node)
  if not render_node then
    return {}
  end

  local snapshot = {}
  if render_node.meta_key then
    table.insert(snapshot, { meta_key = algos.extract_meta_key(render_node.meta_key), path = render_node.path })
  end

  for _, child in ipairs(render_node.children) do
    if child.revealed then
      local child_entries = algos.get_snapshot_from_render_node(child)
      for _, entry in ipairs(child_entries) do
        table.insert(snapshot, entry)
      end
    else
      table.insert(snapshot, { meta_key = algos.extract_meta_key(child.meta_key), path = child.path })
    end
  end

  return snapshot
end

---@param buf_lines string[]
---@return Fyler.Snapshot.Item[]
function algos.get_snapshot_from_buf_lines(buf_lines)
  local snapshot = {}
  local root_path = state.cwd
  local render_node = state.render_node[root_path]
  local stack = { { meta_key = algos.extract_meta_key(render_node.meta_key), path = root_path, indentation = -1 } }
  table.insert(snapshot, { meta_key = algos.extract_meta_key(render_node.meta_key), path = root_path })

  for _, buf_line in
    ipairs(vim.tbl_filter(function(line)
      return line ~= ''
    end, buf_lines))
  do
    local meta_key = algos.extract_meta_key(buf_line)
    local item_name = algos.extract_item_name(buf_line)
    local item_indentation = algos.extract_indentation(buf_line)
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
function algos.get_changes(old_snapshot, new_snapshot)
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

return algos

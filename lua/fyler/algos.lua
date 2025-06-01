local state = require 'fyler.state'
local algos = {}
local uv = vim.uv or vim.loop

---@param line string
---@return integer
function algos.extract_indentation(line)
  return #(line:match '^/?%d+(%s*)' or line:match '^(%s*)' or '')
end

---@param line string
---@return integer?
function algos.extract_meta_key(line)
  return line:match '^/(%d+)'
end

---@param line string
---@return string
function algos.extract_item_name(line)
  return line:match '^/?%d+%s+[^%s]+%s+(.*)$' or line:match '^%s*(.*)$'
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
    local child_entries = algos.get_snapshot_from_render_node(child)
    for _, entry in ipairs(child_entries) do
      table.insert(snapshot, entry)
    end
  end

  return snapshot
end

---@param buf_lines string[]
---@return Fyler.Snapshot.Item[]
function algos.get_snapshot_from_buf_lines(buf_lines)
  local snapshot = {}
  local root_path = uv.cwd() or vim.fn.getcwd(0)
  local render_node = state('rendernodes'):get(root_path)
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
    table.insert(snapshot, { meta_key = meta_key, path = full_path })
    table.insert(stack, { meta_key = meta_key, path = full_path, indentation = item_indentation })
  end

  return snapshot
end

---@return { create: string[], delete: string[], move: { from: string, to: string }[] }
function algos.get_changes(old_snapshot, new_snapshot)
  local function has_snapshot_item(meta_key, snapshot)
    for _, item in ipairs(snapshot) do
      if item.meta_key == meta_key then
        return true
      end
    end

    return false
  end

  local changes = { create = {}, delete = {}, move = {} }
  for _, item in ipairs(new_snapshot) do
    if not item.meta_key then
      table.insert(changes.create, item.path)
    end
  end

  for _, item in ipairs(old_snapshot) do
    if not has_snapshot_item(item.meta_key, new_snapshot) then
      table.insert(changes.delete, item.path)
    end
  end

  return changes
end

return algos

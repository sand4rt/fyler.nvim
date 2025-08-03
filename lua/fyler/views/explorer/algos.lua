local Stack = require("fyler.lib.structs.stack")
local fs = require("fyler.lib.fs")
local store = require("fyler.views.explorer.store")
local util = require("fyler.lib.util")
local M = {}

local api = vim.api

---@param view FylerExplorerView
---@return table
function M.tree_table_from_node(view)
  ---@param node FylerFSItem
  local function get_tbl(node)
    local sub_tbl = store.get_entry(node.id)
    sub_tbl.id = node.id

    if sub_tbl:is_dir() then sub_tbl.children = {} end

    if not node.open then return sub_tbl end

    for _, child in ipairs(node.children) do
      table.insert(sub_tbl.children, get_tbl(child))
    end

    return sub_tbl
  end

  return get_tbl(view.fs_root)
end

---@param view FylerExplorerView
---@return table
function M.tree_table_from_buffer(view)
  if not util.has_valid_bufnr(view.win) then return {} end

  local lines = util.filter_blank_lines(api.nvim_buf_get_lines(view.win.bufnr, 0, -1, false))

  local root, stack = util.tbl_merge(store.get_entry(view.fs_root.id), { id = view.fs_root.id, children = {} }), Stack()
  stack:push { node = root, indent = -1 }

  for _, line in ipairs(lines) do
    local id, name, indent = util.match_contents(line)
    local entry = id and store.get_entry(id)

    while stack:top().indent >= #indent and stack.items:len() > 1 do
      stack:pop()
    end

    local parent = stack:top().node
    local new_node = {
      id = id,
      name = name,
      children = {},
      path = fs.joinpath(parent.path, name),
      type = entry and entry.type or "",
    }

    if entry and entry:is_dir() then stack:push { node = new_node, indent = #indent } end

    table.insert(parent.children, new_node)
  end

  return root
end

---@param view FylerExplorerView
---@return table
function M.compute_fs_actions(view)
  local hash, diffs, not_seen = {}, {}, {}

  local function save_hash(root)
    hash[root.id] = root.path
    not_seen[root.id] = true
    for _, child in ipairs(root.children or {}) do
      save_hash(child)
    end
  end

  save_hash(M.tree_table_from_node(view))
  local function compute_diffs(root)
    if root.id then
      table.insert(diffs, { src = hash[root.id], dst = root.path })
      not_seen[root.id] = false
    else
      table.insert(diffs, { dst = root.path })
    end

    for _, child in ipairs(root.children or {}) do
      compute_diffs(child)
    end
  end

  compute_diffs(M.tree_table_from_buffer(view))

  for id, path in pairs(hash) do
    if not_seen[id] then table.insert(diffs, { src = path }) end
  end

  local actions, groups = { create = {}, delete = {}, move = {}, copy = {} }, {}

  for _, diff in ipairs(diffs) do
    if diff.src and diff.dst then
      groups[diff.src] = groups[diff.src] or {}
      table.insert(groups[diff.src], diff.dst)
    else
      if diff.src then table.insert(actions.delete, diff.src) end
      if diff.dst then table.insert(actions.create, diff.dst) end
    end
  end

  for path, tbl in pairs(groups) do
    tbl = tbl or {}

    vim.list.unique(tbl)

    if #tbl == 1 and tbl[1] == path then goto continue end

    if vim.iter(tbl):any(function(x) return x == path end) then
      vim.iter(tbl):each(function(x)
        if path == x then return end

        table.insert(actions.copy, { src = path, dst = x })
      end)
    else
      table.insert(actions.move, { src = path, dst = tbl[1] })
      table.remove(tbl, 1)

      vim.iter(tbl):each(function(x) table.insert(actions.copy, { src = path, dst = x }) end)
    end

    ::continue::
  end

  return actions
end

return M

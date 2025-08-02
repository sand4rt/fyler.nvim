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
    local sub_tbl = store.get(node.id)
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
  if #lines == 0 then return {} end

  local root, stack = util.tbl_merge(store.get(view.fs_root.id), { id = view.fs_root.id, children = {} }), Stack()
  stack:push { node = root, indent = -1 }

  for _, line in ipairs(lines) do
    local id, name, indent = util.match_contents(line)
    local entry = id and store.get(id)

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
function M.get_diff(view)
  local recent_tree_hash = {}

  local function save_hash(root)
    recent_tree_hash[root.id] = root.path
    for _, child in ipairs(root.children or {}) do
      save_hash(child)
    end
  end

  save_hash(M.tree_table_from_node(view))

  local fs_actions = {
    create = {},
    delete = {},
    move = {},
  }

  local function calculate_fs_actions(root)
    if not root.id then
      table.insert(fs_actions.create, root.path)
    else
      if recent_tree_hash[root.id] ~= root.path then
        table.insert(fs_actions.move, { src = recent_tree_hash[root.id], dst = root.path })
      end

      recent_tree_hash[root.id] = nil
    end

    for _, child in ipairs(root.children or {}) do
      calculate_fs_actions(child)
    end
  end

  calculate_fs_actions(M.tree_table_from_buffer(view))

  for _, v in pairs(recent_tree_hash) do
    if v then table.insert(fs_actions.delete, v) end
  end

  return fs_actions
end

return M

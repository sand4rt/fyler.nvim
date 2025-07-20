local fs = require("fyler.lib.fs")
local regex = require("fyler.views.explorer.regex")
local store = require("fyler.views.explorer.store")
local M = {}

local api = vim.api

---@param view FylerExplorerView
---@return table
function M.tree_table_from_node(view)
  ---@param node FylerFSItem
  local function get_tbl(node)
    local sub_tbl = store.get(node.meta)
    sub_tbl.meta = node.meta

    if sub_tbl:is_directory() then
      sub_tbl.children = {}
    end

    if not node.open then
      return sub_tbl
    end

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
  if not view.win:has_valid_bufnr() then
    return {}
  end

  local buf_lines = vim
    .iter(api.nvim_buf_get_lines(view.win.bufnr, 0, -1, false))
    :filter(function(buf_line)
      return buf_line ~= ""
    end)
    :totable()

  local root = vim.tbl_deep_extend("force", store.get(view.fs_root.meta), {
    meta = view.fs_root.meta,
    children = {},
  })

  local stack = {
    { node = root, indent = -1 },
  }

  for _, buf_line in ipairs(buf_lines) do
    local meta = regex.match_meta(buf_line)
    local name = regex.match_name(buf_line)
    local indent = regex.match_indent(buf_line)
    local metadata = meta and store.get(meta)

    while #stack > 1 and #stack[#stack].indent >= #indent do
      table.remove(stack)
    end

    local parent = stack[#stack].node
    local path = fs.joinpath(parent.path, name)
    local new_node = {
      meta = meta,
      name = name,
      type = (metadata or {}).type or "",
      path = path,
    }

    table.insert(parent.children, new_node)
    if metadata and metadata:is_directory() then
      new_node.children = {}
      table.insert(stack, { node = new_node, indent = indent })
    end
  end

  return root
end

---@param view FylerExplorerView
---@return table
function M.get_diff(view)
  local recent_tree_hash = {}

  local function save_hash(root)
    recent_tree_hash[root.meta] = root.path
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
    if not root.meta then
      table.insert(fs_actions.create, root.path)
    else
      if recent_tree_hash[root.meta] ~= root.path then
        table.insert(fs_actions.move, { src = recent_tree_hash[root.meta], dst = root.path })
      end

      recent_tree_hash[root.meta] = nil
    end

    for _, child in ipairs(root.children or {}) do
      calculate_fs_actions(child)
    end
  end

  calculate_fs_actions(M.tree_table_from_buffer(view))

  for _, v in pairs(recent_tree_hash) do
    if v then
      table.insert(fs_actions.delete, v)
    end
  end

  return fs_actions
end

return M

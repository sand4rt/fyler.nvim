local Ui = require "fyler.lib.ui"
local config = require "fyler.config"
local Component = Ui.Component
local Text = Ui.Text
local Row = Ui.Row
local Column = Ui.Column

local icon_provider
if type(config.values.icon_provider) == "function" then
  icon_provider = config.values.icon_provider
else
  icon_provider = require("fyler.integrations.icon")[config.values.icon_provider]
end

local function isdir(node)
  return node.type == "directory"
end

local function sort_nodes(nodes)
  table.sort(nodes, function(x, y)
    local x_is_dir = isdir(x)
    local y_is_dir = isdir(y)

    if x_is_dir and not y_is_dir then
      return true
    elseif not x_is_dir and y_is_dir then
      return false
    else
      return x.name < y.name
    end
  end)

  return nodes
end

-- Flatten the tree into a list of file entries
local function flatten_tree(node, depth, result)
  depth = depth or 0
  result = result or {}

  if not node or not node.children then
    return result
  end

  local sorted_items = sort_nodes(node.children)

  for _, item in ipairs(sorted_items) do
    local icon, hl = icon_provider(item.type, item.path)

    if item.type == "directory" then
      local icons = config.values.icon
      local is_empty = item.open and item.children and #item.children == 0
      local is_expanded = item.open or false

      icon = is_empty and icons.directory_empty
        or (is_expanded and icons.directory_expanded or icons.directory_collapsed)
        or icon
    end

    -- Add this item to the flattened list
    table.insert(result, {
      item = item,
      depth = depth,
      icon = icon,
      hl = hl,
    })

    -- Recursively add children if they exist
    if item.children and #item.children > 0 then
      flatten_tree(item, depth + 1, result)
    end
  end

  return result
end

local function create_file_content(entry)
  local item, depth, icon, hl = entry.item, entry.depth, entry.icon, entry.hl
  local indentation = Text(string.rep(" ", 2 * depth))

  local is_dir = isdir(item)
  local directory_icon_highlight = "FylerFSDirectoryIcon"
  local directory_name_highlight = "FylerFSDirectoryName"

  local icon_text = ""
  local icon_highlight = is_dir and directory_icon_highlight or hl

  if icon and icon ~= "" then
    icon_text = icon .. " "
  end

  local icon_component = Text(icon_text, {
    highlight = icon_highlight,
  })

  local ref_id_text = Text(string.format("/%05d", item.ref_id))

  local name_highlight = item.git_hlg or (is_dir and directory_name_highlight) or nil
  local name_text = Text(" " .. item.name, {
    highlight = name_highlight,
  })

  -- Return Row of Text components for proper highlighting
  return Row {
    indentation,
    icon_component,
    ref_id_text,
    name_text,
  }
end

local function create_git_symbol(entry)
  local item = entry.item

  if item.git_sym and item.git_hlg then
    return Text(nil, {
      virt_text = { { item.git_sym, item.git_hlg } },
    })
  else
    return Text "" -- Empty text for files without git status
  end
end

---@type UiComponent
local file_tree
---@param node table
---@param depth integer|nil
file_tree = Component.new(function(node, depth)
  depth = depth or 0

  if not node or not node.children then
    return { tag = "file_tree", children = {} }
  end

  -- Flatten the entire tree structure
  local flattened_entries = flatten_tree(node, depth)

  if #flattened_entries == 0 then
    return { tag = "file_tree", children = {} }
  end

  -- Build first column (main content)
  local main_content_column = {}
  for _, entry in ipairs(flattened_entries) do
    table.insert(main_content_column, create_file_content(entry))
  end

  -- Build second column (git symbols)
  local git_symbols_column = {}
  for _, entry in ipairs(flattened_entries) do
    table.insert(git_symbols_column, create_git_symbol(entry))
  end

  -- Return single Row with two Columns
  return {
    tag = "file_tree",
    children = {
      Row {
        Column(main_content_column),
        Column(git_symbols_column),
      },
    },
  }
end)

return file_tree

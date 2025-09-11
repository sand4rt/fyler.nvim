local UiComponent = require "fyler.lib.ui.component"
local components = require "fyler.ui_components"
local config = require "fyler.config"
local Text = components.Text
local Row = components.Row

local icon_provider
if type(config.values.icon_provider) == "function" then
  icon_provider = config.values.icon_provider
else
  icon_provider = require("fyler.integrations.icon")[config.values.icon_provider]
end

local function isdir(node) return node.type == "directory" end

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

local function calculate_line_width(depth, icon, ref_id, name)
  local icon_part = (not icon or icon == "") and "" or icon .. " "
  local ref_id_part = string.format("/%05d", ref_id)
  local name_part = " " .. name

  return (2 * depth) + #icon_part + #ref_id_part + #name_part
end

local function calc_file_tree_width(node, depth)
  depth = depth or 0
  local max_width = 0

  for _, child in ipairs(node.children) do
    local icon = icon_provider(child.type, child.name)
    local width = calculate_line_width(depth, icon, child.ref_id, child.name)

    max_width = math.max(max_width, width)

    if child.children and #child.children > 0 then
      local child_width = calc_file_tree_width(child, depth + 1)
      max_width = math.max(max_width, child_width)
    end
  end

  return max_width
end

local function create_file_row(item, depth, width, icon, hl)
  local indentation = Text(string.rep(" ", 2 * depth))

  local is_dir = isdir(item)
  local directory_icon_highlight = "FylerFSDirectoryIcon"
  local directory_name_highlight = "FylerFSDirectoryName"

  local icon_text = ""
  local icon_highlight = is_dir and directory_icon_highlight or hl

  if icon and icon ~= "" then icon_text = icon .. " " end

  local icon_component = Text(icon_text, {
    highlight = icon_highlight,
  })

  local ref_id_text = Text(string.format("/%05d", item.ref_id))

  local name_highlight = item.git_hlg or (is_dir and directory_name_highlight) or nil
  local name_text = Text(" " .. item.name, {
    highlight = name_highlight,
  })

  local git_text = nil
  if item.git_sym and item.git_hlg then
    git_text = Text(nil, {
      virt_text = { { item.git_sym, item.git_hlg } },
      col = width,
    })
  end

  return Row {
    indentation,
    icon_component,
    ref_id_text,
    name_text,
    git_text,
  }
end

---@type UiComponent
local file_tree
---@param node table
---@param width integer|nil
---@param depth integer|nil
file_tree = UiComponent.new(function(node, width, depth)
  depth = depth or 0
  width = width or calc_file_tree_width(node, depth)

  if not node or not node.children then return { tag = "file_tree", children = {} } end

  local children = {}
  local sorted_items = sort_nodes(node.children)

  for _, item in ipairs(sorted_items) do
    local icon, hl = icon_provider(item.type, item.name)

    if item.type == "directory" then
      local icons = config.values.icon
      local is_empty = item.open and item.children and #item.children == 0
      local is_expanded = item.open or false

      icon = is_empty and icons.directory_empty
        or (is_expanded and icons.directory_expanded or icons.directory_collapsed)
        or icon
    end

    table.insert(children, create_file_row(item, depth, width, icon, hl))

    if item.children and #item.children > 0 then
      local child_tree = file_tree(item, width, depth + 1)
      for _, child in ipairs(child_tree.children) do
        table.insert(children, child)
      end
    end
  end

  return {
    tag = "file_tree",
    children = children,
  }
end)

return file_tree

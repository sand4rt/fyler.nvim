local state = require 'fyler.state'
local filesystem = {}
local uv = vim.uv or vim.loop

---@param line string
---@return integer
local function extract_indentation(line)
  return #(line:match '^/?%d+(%s*)' or line:match '^(%s*)' or '')
end

---@param line string
---@return integer?
local function extract_meta_key(line)
  return line:match '^/(%d+)'
end

---@param line string
---@return string
local function extract_item_name(line)
  return line:match '^%s*(.*)'
end

---@param buf_lines string[]
---@param target_item_index integer
---@return string
local function find_parent_path(buf_lines, target_item_index)
  local target_item_indentation = extract_indentation(buf_lines[target_item_index])
  for item_index = target_item_index - 1, 1, -1 do
    local meta_key = extract_meta_key(buf_lines[item_index])
    local item_indentation = extract_indentation(buf_lines[item_index])
    if meta_key then
      local metadata = state('metadata'):get(meta_key)
      if item_indentation == target_item_indentation then
        return vim.fn.fnamemodify(metadata.path, ':h')
      elseif item_indentation < target_item_indentation then
        if metadata.type == 'directory' then
          return metadata.path
        else
          return vim.fn.fnamemodify(metadata.path, ':h')
        end
      end
    end
  end

  for current_item_index = 1, #buf_lines do
    local meta_key = extract_meta_key(buf_lines[current_item_index])
    if meta_key then
      return vim.fn.fnamemodify(state('metadata'):get(meta_key).path, ':h')
    end
  end

  return (vim.uv or vim.loop).cwd() or vim.fn.getcwd(0)
end

---@param buf_lines string[]
---@return table<"create"|"delete"|"move"|"copy", table>
local function get_parsed_changes(buf_lines)
  local parsed_changes = { create = {}, delete = {}, move = {}, copy = {} }
  for item_index, buf_line in ipairs(buf_lines) do
    local meta_key = extract_meta_key(buf_line)
    if not meta_key then
      table.insert(
        parsed_changes.create,
        string.format('%s/%s', find_parent_path(buf_lines, item_index), extract_item_name(buf_line))
      )
    end
  end

  return parsed_changes
end

function filesystem.synchronize_from_buffer()
  local window = state('windows'):get 'main' ---@type Fyler.Window
  local buf_lines = vim.api.nvim_buf_get_lines(window.bufnr, 0, -1, false)
  local parsed_changes = get_parsed_changes(buf_lines)
  for _, change in ipairs(parsed_changes.create) do
    filesystem.create_fs_item(change)
  end
end

---@param path string
function filesystem.create_fs_item(path)
  local stat = uv.fs_stat(path)
  if stat then
    return
  end
  local path_type = string.sub(path, -1) == '/' and 'directory' or 'file'
  if path_type == 'directory' then
    uv.fs_mkdir(path, 493)
  else
    local fd = uv.fs_open(path, 'w', 438)
    if not fd then
      return
    end
    uv.fs_close(fd)
  end
end

return filesystem

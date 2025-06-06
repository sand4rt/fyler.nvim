local Text = require 'fyler.lib.text'
local algos = require 'fyler.algos'
local state = require 'fyler.state'
local utils = require 'fyler.utils'
local filesystem = {}
local uv = vim.uv or vim.loop

---@param callback function
function filesystem.synchronize_from_buffer(callback)
  local window = state.window.main
  local buf_lines = vim.api.nvim_buf_get_lines(window.bufnr, 0, -1, false)
  local changes = algos.get_changes(
    algos.get_snapshot_from_render_node(state.render_node[uv.cwd() or vim.fn.getcwd(0)]),
    algos.get_snapshot_from_buf_lines(buf_lines)
  )
  if vim.tbl_isempty(changes.create) and vim.tbl_isempty(changes.delete) and vim.tbl_isempty(changes.move) then
    return
  end

  local group_hl = setmetatable({
    create = 'FylerSuccess',
    delete = 'FylerFailure',
    move = 'FylerWarning',
  }, {
    __index = function()
      error 'Operation type not supported'
    end,
  })

  local changes_text = Text.new {}
  for change_group, change_list in pairs(changes) do
    for _, change in ipairs(change_list) do
      changes_text:append(' ' .. string.upper(change_group), group_hl[change_group])
      if type(change) == 'table' then
        changes_text
          :append(' ', 'FylerBlank')
          :append(string.format('%s  %s', change.from, change.to), 'FylerParagraph')
      else
        changes_text:append(' ', 'FylerBlank'):append(change, 'FylerParagraph')
      end

      changes_text:nl()
    end
  end

  utils.confirm(changes_text, function(confirmation)
    if confirmation then
      for _, change in ipairs(changes.create) do
        filesystem.create_fs_item(change)
      end

      for _, change in ipairs(changes.delete) do
        filesystem.delete_fs_item(change)
      end

      for _, change in ipairs(changes.move) do
        filesystem.move_fs_item(change.from, change.to)
      end
    end

    callback()
  end)
end

---@param path string
function filesystem.create_fs_item(path)
  local stat = uv.fs_stat(path)
  if stat then
    error 'Item already exist'
  end

  local path_type = string.sub(path, -1) == '/' and 'directory' or 'file'
  if path_type == 'directory' then
    if not vim.fn.mkdir(path, 'p') then
      error 'Unable to create directory'
    end
  else
    local parent_path = vim.fn.fnamemodify(path, ':h')
    if vim.fn.isdirectory(path) == 0 then
      if not vim.fn.mkdir(parent_path, 'p') then
        error 'Unable to create directory'
      end
    end

    local fd, err, err_name = uv.fs_open(path, 'w', 438)
    if not fd or err then
      error('Unable to create file: ' .. err_name .. err)
    end

    uv.fs_close(fd)
  end

  vim.notify('CREATE: ' .. path, vim.log.levels.INFO)
end

---@param path string
function filesystem.delete_fs_item(path)
  local stat = uv.fs_stat(path)
  if not stat then
    error 'Item does not exists'
  end

  if stat.type == 'directory' then
    vim.fn.delete(path, 'rf')
  elseif stat.type == 'file' then
    vim.fn.delete(path)
  else
    error 'Unable to delete item'
  end

  state.render_node[path]:delete_node()
  vim.notify('DELETE: ' .. path, vim.log.levels.INFO)
end

---@param from string
---@param to string
function filesystem.move_fs_item(from, to)
  local from_stat = uv.fs_stat(from)
  if not from_stat then
    error 'Item does not exists'
  end

  local parent_dir = vim.fn.fnamemodify(to, ':h')
  local parent_stat = uv.fs_stat(parent_dir)
  if not parent_stat then
    filesystem.create_fs_item(parent_dir .. '/')
  end

  uv.fs_rename(from, to)
  state.render_node[from]:delete_node()
  vim.notify('MOVE: ' .. from .. ' ' .. to, vim.log.levels.INFO)
end

return filesystem

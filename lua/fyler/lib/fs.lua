local Text = require 'fyler.lib.text'
local algos = require 'fyler.lib.algos'
local component = require 'fyler.lib.ui.component'
local state = require 'fyler.lib.state'
local api = vim.api
local uv = vim.uv or vim.loop
local M = {}

---@param callback function
function M.synchronize_from_buffer(callback)
  local window = state.get { 'window', 'main' }
  local node = state.get { 'node', state.get { 'cwd' } }
  local buf_lines = api.nvim_buf_get_lines(window.bufnr, 0, -1, false)
  local changes = algos.get_changes(algos.get_snapshot_from_node(node), algos.get_snapshot_from_buf_lines(buf_lines))
  if vim.tbl_isempty(changes.create) and vim.tbl_isempty(changes.delete) and vim.tbl_isempty(changes.move) then
    return
  end

  local hl = setmetatable({
    create = 'FylerSuccess',
    delete = 'FylerFailure',
    move = 'FylerWarning',
  }, {
    __index = function()
      vim.notify 'Operation type not supported'
    end,
  })

  local text = Text.new {}
  for group, list in pairs(changes) do
    for _, change in ipairs(list) do
      text:append(string.upper(group), hl[group]):append ' '
      if type(change) == 'table' then
        text:append(string.format('%s > %s', change.from, change.to), 'FylerParagraph')
      else
        text:append(change, 'FylerParagraph')
      end

      text:nl()
    end
  end

  component.confirm(text, function(confirmation)
    if confirmation then
      for _, change in ipairs(changes.create) do
        M.create_fs_item(change)
      end

      for _, change in ipairs(changes.delete) do
        M.delete_fs_item(change)
      end

      for _, change in ipairs(changes.move) do
        M.move_fs_item(change.from, change.to)
      end
    end

    callback()
  end)
end

---@param path string
function M.create_fs_item(path)
  local stat = uv.fs_stat(path)
  if stat then
    return
  end

  local path_type = string.sub(path, -1) == '/' and 'directory' or 'file'
  if path_type == 'directory' then
    if vim.fn.mkdir(path, 'p') == 0 then
      return
    end
  else
    local parent_path = vim.fn.fnamemodify(path, ':h')
    if vim.fn.isdirectory(path) == 0 then
      if vim.fn.mkdir(parent_path, 'p') == 0 then
        return
      end
    end

    local fd, err = uv.fs_open(path, 'w', 438)
    if not fd or err then
      return
    end

    uv.fs_close(fd)
  end

  vim.notify('CREATE: ' .. path, vim.log.levels.INFO)
end

---@param path string
function M.delete_fs_item(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return
  end

  if stat.type == 'directory' then
    vim.fn.delete(path, 'rf')
  elseif stat.type == 'file' then
    vim.fn.delete(path)
  else
    return
  end

  vim.notify('DELETE: ' .. path, vim.log.levels.INFO)
end

---@param from string
---@param to string
function M.move_fs_item(from, to)
  local from_stat = uv.fs_stat(from)
  if not from_stat then
    return
  end

  local parent_dir = vim.fn.fnamemodify(to, ':h')
  local parent_stat = uv.fs_stat(parent_dir)
  if not parent_stat then
    M.create_fs_item(parent_dir .. '/')
  end

  uv.fs_rename(from, to)
  vim.notify('MOVE: ' .. from .. ' > ' .. to, vim.log.levels.INFO)
end

return M

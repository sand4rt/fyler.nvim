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

  local changes_text = Text.new {}
  for change_group, change_list in pairs(changes) do
    for _, change in ipairs(change_list) do
      if type(change) == 'table' then
      else
        changes_text
          :append(string.upper(change_group), 'FylerHeading')
          :append(' ', 'FylerBlank')
          :append(change, 'FylerParagraph')
      end
    end
  end

  changes_text:nl(2):append('[Y]es', 'FylerSuccess'):append('  ', 'FylerBlank'):append('[N]o', 'FylerFailure')
  utils.confirm(changes_text, function(confirmation)
    if confirmation then
      for _, change in ipairs(changes.create) do
        filesystem.create_fs_item(change)
      end

      for _, change in ipairs(changes.delete) do
        filesystem.delete_fs_item(change)
      end
    end

    callback()
  end)
end

---@param path string
function filesystem.create_fs_item(path)
  local stat = uv.fs_stat(path)
  if stat then
    return
  end

  local path_type = string.sub(path, -1) == '/' and 'directory' or 'file'
  if path_type == 'directory' then
    local success = vim.fn.mkdir(path, 'p')
    if not success then
      return
    end
  else
    local parent_path = vim.fn.fnamemodify(path, ':h')
    if vim.fn.isdirectory(path) == 0 then
      local success = vim.fn.mkdir(parent_path, 'p')
      if not success then
        return
      end
    end

    local fd, err, err_name = uv.fs_open(path, 'w', 438)
    if not fd or err then
      vim.notify(err .. err_name, vim.log.levels.ERROR, { title = 'Fyler.nvim' })
      return
    end

    uv.fs_close(fd)
  end

  vim.notify('CREATE: ' .. path, vim.log.levels.INFO)
end

---@param path string
function filesystem.delete_fs_item(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return
  end

  if stat.type == 'directory' then
    vim.fn.delete(path, 'rf')
  elseif stat.type == 'file' then
    vim.fn.delete(path)
  else
    vim.notify('Unable to delete item', vim.log.levels.ERROR)
  end

  state.render_node[path]:delete_node()
  vim.notify('DELETE: ' .. path, vim.log.levels.INFO)
end

return filesystem

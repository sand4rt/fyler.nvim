local utils = {}

---@param bufnr? integer
---@return boolean
function utils.is_valid_buf(bufnr)
  if not bufnr then
    return false
  end

  return vim.api.nvim_buf_is_valid(bufnr)
end

---@param winid? integer
---@return boolean
function utils.is_valid_win(winid)
  if not winid then
    return false
  end

  return vim.api.nvim_win_is_valid(winid)
end

---@param window_instance Fyler.Window
---@return vim.api.keyset.win_config
function utils.get_win_config(window_instance)
  return {
    style = 'minimal',
    width = math.ceil(window_instance.width * vim.o.columns),
    split = window_instance.split,
  }
end

---@param instance Fyler.Window
function utils.show_window(instance)
  if instance.winid and utils.is_valid_win(instance.winid) then
    return
  end

  instance.bufnr = vim.api.nvim_create_buf(false, true)
  instance.winid = vim.api.nvim_open_win(instance.bufnr, instance.enter, utils.get_win_config(instance))
end

---@param instance Fyler.Window
function utils.hide_window(instance)
  if not (instance.winid and utils.is_valid_win(instance.winid)) then
    return
  end

  vim.api.nvim_win_close(instance.winid, true)

  if not (instance.bufnr and utils.is_valid_buf(instance.bufnr)) then
    return
  end

  vim.api.nvim_buf_delete(instance.bufnr, { force = true })
end

---@param instance Fyler.Window
---@param win_config vim.api.keyset.win_config
function utils.set_win_config(instance, win_config)
  if instance.winid and utils.is_valid_win(instance.winid) then
    vim.api.nvim_win_set_config(
      instance.winid,
      vim.tbl_deep_extend('force', vim.api.nvim_win_get_config(instance.winid), win_config)
    )
  end
end

---@param instance Fyler.Window
---@param option string
---@param value any
function utils.set_win_option(instance, option, value)
  if vim.wo then
    vim.wo[instance.winid][option] = value
  else
    vim.api.nvim_set_option_value(option, value, { win = instance.winid })
  end
end

---@param instance Fyler.Window
---@param option string
---@param value any
function utils.set_buf_option(instance, option, value)
  if vim.bo then
    vim.bo[instance.bufnr][option] = value
  else
    vim.api.nvim_set_option_value(option, value, { buf = instance.bufnr })
  end
end

return utils

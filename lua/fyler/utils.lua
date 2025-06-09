local config = require 'fyler.config'
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

---@return integer, integer
local function get_view_size()
  local vw = vim.o.columns
  local vh = vim.o.lines - vim.o.cmdheight

  if vim.o.laststatus ~= 0 then
    vh = vh - 1
  end

  return vw, vh
end

---@param window_instance Fyler.Window
---@return vim.api.keyset.win_config
function utils.get_win_config(window_instance)
  if window_instance.split then
    return {
      style = 'minimal',
      width = math.ceil(window_instance.width * vim.o.columns),
      split = window_instance.split,
    }
  else
    local vw, vh = get_view_size()
    return {
      relative = 'editor',
      style = 'minimal',
      width = math.min(math.ceil(window_instance.width * vim.o.columns) + window_instance.width_delta, vw),
      height = math.min(math.ceil(window_instance.height * vim.o.lines) + window_instance.height_delta, vh),
      col = math.min(math.floor(window_instance.col * vw) + window_instance.col_delta, vw),
      row = math.min(math.floor(window_instance.row * vh) + window_instance.row_delta, vh),
      border = window_instance.border,
    }
  end
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

---@class Fyler.Window.Keymap.Config
---@field mode string|string[]
---@field lhs string
---@field rhs string|function|Fyler.Action
---@field options? vim.keymap.set.Opts

---@param key_config Fyler.Window.Keymap.Config
function utils.set_keymap(key_config)
  key_config = key_config or {}
  local mode = key_config.mode or 'n'
  local lhs = key_config.lhs
  local rhs = key_config.rhs
  local opts = vim.tbl_deep_extend('force', key_config.options or {}, {
    silent = true,
    noremap = true,
    desc = (type(rhs) == 'table' and rhs:get_name() or nil),
  })

  if type(rhs) == 'string' then
    vim.keymap.set(mode, lhs, rhs, opts)
  elseif type(rhs) == 'function' then
    vim.keymap.set(mode, lhs, rhs, opts)
  else
    vim.keymap.set(mode, lhs, function()
      rhs()
    end, opts)
  end
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
  -- Only proceed if instance is a table
  if type(instance) ~= 'table' then
    return
  end

  -- Check winid is a number and is a valid window
  if type(instance.winid) == 'number' and utils.is_valid_win(instance.winid) then
    vim.api.nvim_win_close(instance.winid, true)
  end

  -- Check bufnr is a number and is a valid buffer
  if type(instance.bufnr) == 'number' and utils.is_valid_buf(instance.bufnr) then
    vim.api.nvim_buf_delete(instance.bufnr, { force = true })
  end
end

---@generic T
---@param tbl T[]
---@param target T
---@return integer?
function utils.indexof(tbl, target)
  for index, element in ipairs(tbl) do
    if target == element then
      return index
    end
  end

  return nil
end

---@return function
function utils.hide_cursor()
  local original_guicursor = vim.go.guicursor
  vim.go.guicursor = 'a:FylerHiddenCursor/FylerHiddenCursor'

  return function()
    vim.go.guicursor = 'a:'
    if original_guicursor ~= '' then
      vim.go.guicursor = original_guicursor
    end
  end
end

---@param text Fyler.Text
---@param callback function
utils.confirm = vim.schedule_wrap(function(text, callback)
  local vw, vh = get_view_size()
  local window_options = {
    enter = true,
    width = 0,
    height = 0,
    width_delta = text:get_max_span() + 1,
    height_delta = #text.lines + 1,
    col = 0,
    row = 0,
    border = 'rounded',
  }
  window_options.col_delta = math.floor((vw - window_options.width_delta) * 0.5)
  window_options.row_delta = math.floor((vh - window_options.height_delta) * 0.5)

  local window = require('fyler.lib.window').new(window_options)
  local restore_cursor = utils.hide_cursor()
  utils.show_window(window)
  utils.set_buf_option(window, 'modifiable', false)

  utils.set_win_option(
    window,
    'winhighlight',
    table.concat({ 'Normal:Normal', 'FloatBorder:FloatBorder', 'FloatTitle:FloatTitle' }, ',')
  )

  vim.api.nvim_create_autocmd('WinClosed', {
    group = vim.api.nvim_create_augroup('Fyler', { clear = true }),
    buffer = window.bufnr,
    callback = function()
      utils.hide_window(window)
      restore_cursor()
    end,
  })

  utils.set_keymap {
    mode = 'n',
    lhs = 'y',
    rhs = function()
      utils.hide_window(window)
      restore_cursor()
      callback(true)
    end,
    options = {
      buffer = window.bufnr,
    },
  }
  utils.set_keymap {
    mode = 'n',
    lhs = 'n',
    rhs = function()
      utils.hide_window(window)
      restore_cursor()
      callback(false)
    end,
    options = {
      buffer = window.bufnr,
    },
  }

  local button_success = '(Y)es '
  local button_failure = ' (N)o'
  local columns = vim.api.nvim_win_get_width(window.winid)
  text
    :nl()
    :append(string.rep(' ', math.floor((columns - #(button_success .. button_failure)) * 0.5)), 'FylerBlank')
    :append(button_success, 'FylerSuccess')
    :append(button_failure, 'FylerFailure')
    :append(string.rep(' ', math.floor((columns - #(button_success .. button_failure)) * 0.5)), 'FylerBlank')
    :render(window.bufnr)
end)

return utils

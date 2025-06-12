local helper = require 'fyler.lib.ui.helper'
local state = require 'fyler.lib.state'
local api = vim.api
local uv = vim.uv or vim.loop
local M = {}

---@param options? table
function M.show(options)
  local Node = require 'fyler.lib.node'
  local Window = require 'fyler.lib.ui.window'
  local algos = require 'fyler.lib.algos'
  local config = require 'fyler.lib.config'
  local git = require 'fyler.lib.git'
  local path = require 'fyler.lib.path'
  options = options or {}
  for _, window in pairs(state.get { 'window' } or {}) do
    helper.hide_window(window)
  end

  if options.cwd and options.cwd ~= state.get { 'cwd' } then
    state.reset()
  end

  local cwd = path.toabsolute(options.cwd) or path.getcwd()
  state.set({ 'cwd' }, cwd)
  state.set({ 'node', cwd }, state.get { 'node', cwd } or Node.new {
    name = vim.fn.fnamemodify(cwd, ':t'),
    path = cwd,
    type = 'directory',
    revealed = true,
  })

  if config.values.view_config.git_status.enable and not M.git_watcher then
    local timer = uv.new_timer()
    if timer then
      timer:start(0, 2000, vim.schedule_wrap(git.update_status))
    end

    M.git_watcher = true
  end

  local node = state.get { 'node', cwd }
  local window = Window.new {
    enter = true,
    width = config.values.window_config.width,
    split = options.split or config.values.window_config.split,
  }

  state.set({ 'window', 'main' }, window)
  state.set({ 'recent', 'winid' }, api.nvim_get_current_win())
  helper.show_window(window)

  for option, value in pairs {
    filetype = 'fyler',
    syntax = 'fyler',
    buftype = 'acwrite',
  } do
    vim.bo[window.bufnr][option] = value
  end

  for option, value in pairs {
    number = config.values.window_options.number,
    relativenumber = config.values.window_options.relativenumber,
    cursorline = true,
    conceallevel = 3,
    concealcursor = 'nvic',
  } do
    vim.wo[window.winid][option] = value
  end

  api.nvim_buf_set_name(window.bufnr, string.format('fyler://%s', cwd))

  api.nvim_create_autocmd('WinClosed', {
    group = M.augroup,
    buffer = window.bufnr,
    callback = function()
      helper.hide_window(window)
      state.set({ 'window', 'main' }, nil)
    end,
  })

  api.nvim_create_autocmd('CursorMoved', {
    group = M.augroup,
    buffer = window.bufnr,
    callback = function()
      local current_line = api.nvim_get_current_line()
      local meta_key = algos.extract_meta_key(current_line)
      if not meta_key then
        return
      end

      local current_row, current_col = unpack(api.nvim_win_get_cursor(0))
      local bound, _ = current_line:find '%s+/%d+'
      if bound and current_col >= math.max(0, bound - 2) then
        vim.schedule(function()
          api.nvim_win_set_cursor(0, { math.max(1, current_row), math.max(0, bound - 2) })
        end)
      end

      state.set({ 'recent', 'cursor' }, { current_row, current_col })
    end,
  })

  api.nvim_create_autocmd('ModeChanged', {
    pattern = { '*:i', '*:c', '*:v', '*:V', '*:R' }, --- TODO: probably need to add more patterns
    group = M.augroup,
    callback = function(args)
      if args.buf == window.bufnr then
        state.set({ 'recent', 'isediting' }, true)
      end
    end,
  })

  node:totext():trim():render(window.bufnr)
  if state.get { 'recent', 'cursor' } then
    vim.schedule(function()
      api.nvim_win_set_cursor(window.winid, state.get { 'recent', 'cursor' })
    end)
  end

  vim.keymap.set('n', 'q', function()
    helper.hide_window(window)
  end, { buffer = window.bufnr, silent = true, noremap = true })
  vim.keymap.set('n', '<cr>', function()
    require('fyler.lib.actions').toggle_reveal()
  end, { buffer = window.bufnr, silent = true, noremap = true })
end

---@param options Fyler.Config
function M.setup(options)
  if M.has_setup then
    return
  end

  local config = require 'fyler.lib.config'
  M.augroup = api.nvim_create_augroup('Fyler', { clear = true })

  config.set_defaults(options)

  api.nvim_create_autocmd('BufWriteCmd', {
    nested = true,
    pattern = 'fyler://*',
    callback = function()
      require('fyler.lib.actions').synchronize()
    end,
  })

  api.nvim_create_autocmd('BufReadCmd', {
    nested = true,
    pattern = 'fyler://*',
    callback = function()
      local window = state.get { 'window', 'main' }
      local node = state.get { 'node', state.get { 'cwd' } }
      local recent_cursor = state.get { 'recent', 'cursor' }
      node:totext():trim():render(window.bufnr)
      vim.bo[window.bufnr].filetype = 'fyler'
      vim.bo[window.bufnr].syntax = 'fyler'
      if not recent_cursor then
        return
      end

      vim.schedule(function()
        api.nvim_win_set_cursor(window.winid, recent_cursor)
      end)
    end,
  })

  if config.values.default_explorer then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    if vim.fn.exists '#FileExplorer' then
      api.nvim_create_augroup('FileExplorer', { clear = true })
    end

    if vim.v.vim_did_enter == 0 then
      local arg_path = vim.fn.argv(0)
      local first_arg = type(arg_path) == 'string' and arg_path or arg_path[1]
      if vim.fn.isdirectory(first_arg) == 0 then
        return
      end

      local current_bufnr = api.nvim_get_current_buf()
      if helper.is_valid_bufnr(current_bufnr) then
        api.nvim_buf_delete(current_bufnr, { force = true })
      end

      vim.schedule(function()
        M.show { cwd = arg_path }
      end)
    end
  end

  M.has_setup = true
end

function M.complete(arglead)
  if arglead:find '^split=' then
    return {
      'split=left',
      'split=above',
      'split=right',
      'split=below',
    }
  end

  if arglead:find '^cwd=' then
    return {
      'cwd=' .. uv.cwd(),
    }
  end

  return vim.tbl_filter(function(arg)
    return arg:match('^' .. arglead)
  end, {
    'split=',
    'cwd=',
  })
end

return M

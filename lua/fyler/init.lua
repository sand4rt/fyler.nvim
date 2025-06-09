---@brief [[
--- Fyler.nvim is a file manager which can edit file system like a buffer.
---
--- How it different from |oil.nvim|?
--- - It provides tree view
---@brief ]]

---@tag fyler.nvim
---@config { ["name"] = "INTRODUCTION" }

local RenderNode = require 'fyler.lib.rendernode'
local Window = require 'fyler.lib.window'
local algos = require 'fyler.algos'
local config = require 'fyler.config'
local state = require 'fyler.state'
local utils = require 'fyler.utils'
local uv = vim.uv or vim.loop

local M = {}

function M.hide()
  utils.hide_window(state.window.main)
end

---@param options? table
function M.show(options)
  options = options or {}
  -- Check if already open
  if state.window.main then
    utils.hide_window(state.window.main)
  end

  -- Clear state for fresh startup
  if options.cwd and options.cwd ~= state.cwd then
    for k, _ in pairs(state) do
      state[k] = nil
    end

    state.cwd = options.cwd or uv.cwd() or vim.fn.getcwd(0)
  else
    state.cwd = uv.cwd() or vim.fn.getcwd(0)
  end

  local render_node = vim.tbl_isempty(state.render_node[state.cwd])
      and RenderNode.new {
        name = vim.fn.fnamemodify(state.cwd, ':t'),
        path = state.cwd,
        type = 'directory',
        revealed = true,
      }
    or state.render_node[state.cwd]
  local window = Window.new {
    enter = true,
    width = config.values.window_config.width,
    split = options.split or config.values.window_config.split,
  }

  -- Sync states
  state.window.main = window
  state.window_id.user = vim.api.nvim_get_current_win()
  state.render_node[render_node.path] = render_node
  utils.show_window(window)

  -- Setup options
  utils.set_buf_option(window, 'filetype', 'fyler-main')
  utils.set_buf_option(window, 'syntax', 'fyler')
  utils.set_buf_option(window, 'buftype', 'acwrite')
  utils.set_win_option(window, 'number', config.values.window_options.number)
  utils.set_win_option(window, 'relativenumber', config.values.window_options.relativenumber)
  utils.set_win_option(window, 'cursorline', true)
  utils.set_win_option(window, 'conceallevel', 3)
  utils.set_win_option(window, 'concealcursor', 'nvic')
  vim.api.nvim_buf_set_name(window.bufnr, string.format('fyler://%s', state.cwd))
  vim.api.nvim_create_autocmd('WinClosed', {
    group = vim.api.nvim_create_augroup('Fyler', { clear = true }),
    buffer = window.bufnr,
    callback = function()
      -- Switch to the user's original window before hiding
      if state.window_id.user and vim.api.nvim_win_is_valid(state.window_id.user) then
        vim.api.nvim_set_current_win(state.window_id.user)
      end

      utils.hide_window(window)
    end,
  })

  -- Constrain cursor position
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = vim.api.nvim_create_augroup('Fyler', { clear = true }),
    buffer = window.bufnr,
    callback = function()
      local current_line = vim.api.nvim_get_current_line()
      local meta_key = algos.extract_meta_key(current_line)
      if not meta_key then
        return
      end

      local node = render_node:find(state.meta_data[meta_key].path)
      if not node then
        return
      end

      local current_row, current_col = unpack(vim.api.nvim_win_get_cursor(0))
      local bound, _ = current_line:find '%s+/%d+'
      if bound and current_col >= bound - 1 then
        vim.api.nvim_win_set_cursor(0, { current_row, bound - 1 })
      end

      state.cursor = { current_row, current_col }
    end,
  })

  -- Apply mappings
  for mode, mappings in pairs(require('fyler.mappings').default_mappings.main or {}) do
    for k, v in pairs(mappings) do
      utils.set_keymap {
        mode = mode,
        lhs = k,
        rhs = v,
        options = {
          buffer = window.bufnr,
        },
      }
    end
  end

  render_node:get_equivalent_text():remove_trailing_empty_lines():render(window.bufnr)
  if not vim.tbl_isempty(state.cursor) then
    vim.api.nvim_win_set_cursor(window.winid, state.cursor)
  end
end

function M.setup(options)
  config.set_defaults(options)

  if config.values.default_explorer then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    -- If netrw was already loaded, clear this augroup
    if vim.fn.exists '#FileExplorer' then
      vim.api.nvim_create_augroup('FileExplorer', { clear = true })
    end

    vim.api.nvim_create_autocmd('VimEnter', {
      group = vim.api.nvim_create_augroup('Fyler', { clear = true }),
      callback = function()
        local arg_path = vim.fn.argv(0)
        local first_arg = type(arg_path) == 'string' and arg_path or arg_path[1]
        if vim.fn.isdirectory(first_arg) == 0 then
          return
        end

        local current_bufnr = vim.api.nvim_get_current_buf()
        if utils.is_valid_buf(current_bufnr) then
          vim.api.nvim_buf_delete(current_bufnr, { force = true })
        end

        require('fyler').show { cwd = arg_path }
      end,
    })
  end
end

return M

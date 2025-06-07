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
local luv = vim.uv or vim.loop

local M = {}

function M.hide()
  utils.hide_window(state.window.main)
end

---@param options table
function M.show(options)
  -- Check if already open
  if state.window.main then
    utils.hide_window(state.window.main)
  end

  -- Clear state for fresh startup
  for k, _ in pairs(state) do
    state[k] = nil
  end

  -- Check if existing render_node otherwise create new
  local cwd = options.cwd or luv.cwd() or vim.fn.getcwd(0)
  local render_node = vim.tbl_isempty(state.render_node[cwd])
      and RenderNode.new {
        name = vim.fn.fnamemodify(luv.cwd() or '', ':t'),
        path = cwd,
        type = 'directory',
        revealed = true,
      }
    or state.render_node[cwd]
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
  utils.set_win_option(window, 'number', config.values.window_options.number)
  utils.set_win_option(window, 'relativenumber', config.values.window_options.relativenumber)
  utils.set_win_option(window, 'cursorline', true)
  utils.set_win_option(window, 'conceallevel', 3)
  utils.set_win_option(window, 'concealcursor', 'nvic')
  utils.create_autocmd('WinClosed', {
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
  utils.create_autocmd('CursorMoved', {
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
    local netrw_bufname
    -- Clear FileExplorer autocmds to prevent netrw from launching
    pcall(vim.api.nvim_clear_autocmds, { group = 'FileExplorer' })
    -- Safety: Also clear on VimEnter
    vim.api.nvim_create_autocmd('VimEnter', {
      pattern = '*',
      once = true,
      callback = function()
        pcall(vim.api.nvim_clear_autocmds, { group = 'FileExplorer' })
      end,
    })

    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('FylerHijackNetrw', { clear = true }),
      pattern = '*',
      callback = function()
        vim.schedule(function()
          -- Don't hijack if already in netrw
          if vim.bo[0].filetype == 'netrw' then
            return
          end

          local bufname = vim.api.nvim_buf_get_name(0)
          if vim.fn.isdirectory(bufname) == 0 then
            local _, netrw_buf = pcall(vim.fn.expand, '#:p:h')
            netrw_bufname = netrw_buf or ''

            return
          end

          if netrw_bufname == bufname then
            netrw_bufname = nil
            return
          else
            netrw_bufname = bufname
          end

          -- Wipe the buffer so you don't leave a dummy buffer open
          vim.api.nvim_buf_delete(0, {})
          -- Launch plugin
          require('fyler').show()
        end)
      end,
      desc = 'fyler.nvim replacement for netrw',
    })
  end
end

return M

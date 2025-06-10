if vim.g.loaded_fyler == 1 then
  return
end
vim.g.loaded_fyler = 1

local highlights = {
  FylerNormal = { default = true, link = 'Normal' },
  FylerBorder = { default = true, link = 'FloatBorder' },
  FylerTitle = { default = true, link = 'Directory' },
  FylerSuccess = { default = true, link = 'String' },
  FylerFailure = { default = true, link = 'Error' },
  FylerWarning = { default = true, link = 'Constant' },
  FylerBlank = { default = true, link = 'NonText' },
  FylerHeading = { default = true, link = 'Title' },
  FylerParagraph = { default = true, link = 'NavicText' },
  FylerHiddenCursor = { default = true, nocombine = true, blend = 100 },
}

for k, v in pairs(highlights) do
  vim.api.nvim_set_hl(0, k, v)
end

local uv = vim.uv or vim.loop

-- TODO: Have to research more about `BufWriteCmd`
vim.api.nvim_create_autocmd('BufWriteCmd', {
  pattern = 'fyler://*',
  callback = function()
    require('fyler.actions').synchronize()
  end,
})

-- Focus on current buffer
-- TODO: Need a look around for optimization and potential bugs
vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('FylerAction', { clear = true }),
  callback = function(args)
    local state = require 'fyler.state'
    local RenderNode = require 'fyler.lib.rendernode'
    local utils = require 'fyler.utils'
    if not (utils.is_valid_win(state.window.main.winid) and utils.is_valid_buf(state.window.main.bufnr)) then
      return
    end

    if args.file == '' then
      return
    end

    state.cwd = uv.cwd() or vim.fn.getcwd(0)
    state.render_node[state.cwd] = vim.tbl_isempty(state.render_node[state.cwd])
        and RenderNode.new {
          name = vim.fn.fnamemodify(state.cwd, ':t'),
          path = state.cwd,
          type = 'directory',
          revealed = true,
        }
      or state.render_node[state.cwd]

    local current_path = vim.fs.normalize(state.cwd)
    local target_path = vim.fs.normalize(args.file)
    if not vim.startswith(target_path, current_path) then
      return
    end

    state.render_node[state.cwd].revealed = true
    if current_path == target_path then
      return
    end

    local relative_path = string.sub(target_path, #current_path + 2)
    local segments = vim.split(relative_path, '/', { plain = true })
    local current_node = state.render_node[state.cwd]
    for _, segment in ipairs(segments) do
      local next_path = current_path .. '/' .. segment
      current_path = next_path

      local child = current_node:find(next_path)
      if not child then
        for _, item in ipairs(current_node:scan_dir()) do
          if item.path == next_path then
            current_node:add_child(item)
            child = current_node:find(next_path)
            break
          end
        end
      end

      if child then
        child.revealed = true
        current_node = child
      else
        break
      end
    end

    state.render_node[state.cwd]:get_equivalent_text():remove_trailing_empty_lines():render(state.window.main.bufnr)

    local line_number = utils.find_word_line_from_buffer(state.window.main.bufnr, current_node.meta_key)
    if line_number then
      state.cursor = { line_number, 0 }
      vim.api.nvim_win_set_cursor(state.window.main.winid, state.cursor)
    end
  end,
})

vim.api.nvim_create_user_command('Fyler', function(args)
  local options = {}
  for _, farg in ipairs(args.fargs) do
    local key, value = unpack(vim.split(farg, '='))
    options[key] = value
  end

  require('fyler').show(options)
end, {
  nargs = '*',
  complete = function(_, cmd_line)
    local option_specs = { cwd = {}, split = { 'right', 'below', 'left', 'above' } }
    local parts = vim.split(cmd_line, '%s+')
    local last_part = parts[#parts] or ''
    if last_part:find '=' then
      local option_name = last_part:match '^(.-)='
      if option_name and option_specs[option_name] then
        return option_specs[option_name]
      end
      return {}
    end

    local used_options = {}
    for _, part in ipairs(parts) do
      local opt = part:match '^(.-)='
      if opt then
        used_options[opt] = true
      end
    end

    local completions = {}
    for opt, _ in pairs(option_specs) do
      if not used_options[opt] then
        table.insert(completions, opt .. '=')
      end
    end

    return completions
  end,
})

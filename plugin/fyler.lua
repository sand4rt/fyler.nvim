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
    -- All available options with their possible values
    local option_specs = {
      cwd = {}, -- Empty means no specific value completions
      split = { 'right', 'below', 'left', 'above' },
    }

    -- Parse command line
    local parts = vim.split(cmd_line, '%s+')
    local last_part = parts[#parts] or ''

    -- Check if we're completing a value (after =)
    if last_part:find '=' then
      local option_name = last_part:match '^(.-)='
      if option_name and option_specs[option_name] then
        return option_specs[option_name]
      end
      return {}
    end

    -- Otherwise complete option names
    local used_options = {}
    for _, part in ipairs(parts) do
      local opt = part:match '^(.-)='
      if opt then
        used_options[opt] = true
      end
    end

    -- Generate available options
    local completions = {}
    for opt, _ in pairs(option_specs) do
      if not used_options[opt] then
        table.insert(completions, opt .. '=')
      end
    end

    return completions
  end,
})

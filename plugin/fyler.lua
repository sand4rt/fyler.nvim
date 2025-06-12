if vim.g.loaded_fyler == 1 then
  return
end

vim.g.loaded_fyler = 1

local api = vim.api
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
  api.nvim_set_hl(0, k, v)
end

api.nvim_create_user_command('Fyler', function(args)
  local options = {}
  for _, farg in ipairs(args.fargs) do
    local key, value = unpack(vim.split(farg, '='))
    options[key] = value
  end

  require('fyler').show(options)
end, {
  nargs = '*',
  complete = require('fyler').complete,
})

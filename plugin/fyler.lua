vim.api.nvim_create_user_command('Fyler', function(args)
  local opts = {}
  for _, farg in ipairs(args.fargs) do
    local key, value = unpack(vim.split(farg, '='))
    opts[key] = value
  end

  require('fyler').open(opts)
end, {
  nargs = '*',
  complete = require('fyler').complete,
})

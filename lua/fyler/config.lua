local config = {}

local defaults = {
  window_options = {
    number = true,
    relativenumbers = true,
  },
  window_config = {
    width = 0.3,
    split = 'right',
  },
}

function config.set_defaults(options)
  config.values = vim.tbl_deep_extend('force', defaults, options or {})
  config.values.augroup = vim.api.nvim_create_augroup('Fyler', { clear = true })
  config.values.namespace = { highlights = vim.api.nvim_create_namespace 'FylerHighlights' }
end

return config

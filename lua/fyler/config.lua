local config = {}

local defaults = {
  window_options = {
    number = true,
    relativenumbers = true,
  },
}

function config.set_defaults(options)
  config.values = vim.tbl_deep_extend('force', defaults, options or {})
  config.values.namespace = {
    highlights = vim.api.nvim_create_namespace 'FylerHighlights',
  }
  config.values.augroup = vim.api.nvim_create_augroup('Fyler', { clear = true })
end

return config

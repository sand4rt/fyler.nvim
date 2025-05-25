local config = {}

function config.set_defaults()
  config.values = {}
  config.values.namespace = {
    highlights = vim.api.nvim_create_namespace 'FylerHighlights',
  }
  config.values.augroup = vim.api.nvim_create_augroup('Fyler', { clear = true })
end

return config

local config = {}

function config.set_defaults()
  config.values = {}
  config.values.namespace = vim.api.nvim_create_namespace 'Fyler'
end

return config

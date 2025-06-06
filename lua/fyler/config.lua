---@brief [[
--- Fyler supports plenty of options to customize. Following are default values
---
--- >lua
--- <pre>
---   local defaults = {
---     close_on_open = true,
---     default_explorer = false,
---     view = {
---       icons = {
---         enable = true
---       }
---     },
---     window_config = {
---       width = 0.3,
---       split = 'right',
---     },
---     window_options = {
---       number = true,
---       relativenumbers = true,
---     },
---   }
--- </pre>
---@brief ]]

---@tag fyler.config
---@config { ["name"] = "CONFIGURATION" }

local config = {}

local defaults = {
  close_on_open = true,
  default_explorer = false,
  window_config = {
    width = 0.4,
    split = 'right',
  },
  window_options = {
    number = true,
    relativenumbers = true,
  },
}

function config.set_defaults(options)
  config.values = vim.tbl_deep_extend('force', defaults, options or {})
  config.values.augroup = vim.api.nvim_create_augroup('Fyler', { clear = true })
  config.values.namespace = { highlights = vim.api.nvim_create_namespace 'FylerHighlights' }
end

return config

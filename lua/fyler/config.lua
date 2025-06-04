---@brief [[
--- Fyler supports plenty of options to customize. Following are default values
---
--- >lua
--- <pre>
---   local defaults = {
---     window_options = {
---       number = true,
---       relativenumbers = true,
---     },
---     window_config = {
---       width = 0.3,
---       split = 'right',
---     },
---   }
---   hijack_netrw = false,
---   close_on_file_open = false,
--- </pre>
---@brief ]]

---@tag fyler.config
---@config { ["name"] = "CONFIGURATION" }

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
  hijack_netrw = false,
  close_on_file_open = false,
}

function config.set_defaults(options)
  config.values = vim.tbl_deep_extend('force', defaults, options or {})
  config.values.augroup = vim.api.nvim_create_augroup('Fyler', { clear = true })
  config.values.namespace = { highlights = vim.api.nvim_create_namespace 'FylerHighlights' }

  if config.values.hijack_netrw then
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
      group = vim.api.nvim_create_augroup('fyler-hijack-netrw', { clear = true }),
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

          -- Call your plugin's open function
          require('fyler').show(netrw_bufname)
        end)
      end,
      desc = 'fyler.nvim replacement for netrw',
    })
  end
end

return config

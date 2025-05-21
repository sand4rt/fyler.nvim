vim.env.LAZY_STDPATH = '.tests'

load(vim.fn.system 'curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua')()

local is_ci = not (vim.env.GITHUB_ACTIONS == nil)
local fyler_spec = is_ci and { 'A7Lavinraj/fyler.nvim' } or { dir = '~/workspace/development/fyler.nvim' }

require('lazy.minit').setup {
  spec = {
    fyler_spec,
    { 'echasnovski/mini.test', lazy = false },
  },
}

require('mini.test').run {
  collect = {
    find_files = function()
      return vim.fn.globpath('lua', '**/test_*.lua', true, true)
    end,
  },
}

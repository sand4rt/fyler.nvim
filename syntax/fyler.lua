if vim.b.current_syntax then
  return
end

vim.cmd [[
  syntax match FylerMetaKey / \/\d*$/ conceal
]]

vim.b.current_syntax = 'fyler'

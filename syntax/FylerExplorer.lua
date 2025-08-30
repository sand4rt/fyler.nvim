vim.cmd [[
  if exists("b:current_syntax")
    finish
  endif

  syn match FylerExplorerItemID /\/\d* / conceal

  let b:current_syntax = "FylerExplorer"
]]

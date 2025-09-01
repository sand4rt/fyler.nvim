vim.cmd [[
  if exists("b:current_syntax")
    finish
  endif

  syn match FylerExplorerMeta /\/\d* / conceal

  let b:current_syntax = "FylerExplorer"
]]

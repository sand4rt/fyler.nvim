if exists("b:current_syntax")
  finish
endif

syntax match FylerMetaKey /^\/\d* / conceal

let b:current_syntax = 'fyler'

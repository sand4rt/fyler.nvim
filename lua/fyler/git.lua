local git = {}

local function to_absolute(rel_path)
  if not rel_path or rel_path == '' then
    return ''
  end

  return vim.fn.fnamemodify(rel_path:gsub('[\r\n]+', ''), ':p:gs?\\?/?')
end

function git.status()
  if not vim.fn.system('git rev-parse --is-inside-work-tree'):match 'true' then
    return {}
  end

  local status_str = vim.fn.system('git status --porcelain -z'):gsub('^%s*', ''):gsub('\1$', '')
  local git_status = {}
  for _, entry in ipairs(vim.split(status_str, '\1')) do
    local raw_status, file_path = entry:match '(.*)%s(.*)'
    git_status[to_absolute(file_path)] = raw_status
  end

  return git_status
end

return git

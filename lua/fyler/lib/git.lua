local state = require 'fyler.lib.state'
local M = {}
local recent_status = ''

function M.update_status()
  vim.system({ 'git', 'rev-parse', '--is-inside-work-tree' }, nil, function(out1)
    if out1.code == 0 and vim.startswith(out1.stdout or '', 'true') then
      vim.system({ 'git', 'status', '--porcelain', '-z' }, nil, function(out2)
        if state.get { 'recent', 'isediting' } or recent_status == out2.stdout then
          return
        end

        local git_status = {}
        local stdout = out2.stdout or ''
        recent_status = stdout
        for _, entry in ipairs(vim.split(stdout, '\0', { plain = true })) do
          local raw_status, path = unpack(vim.split(entry:gsub('^%s*', ''):gsub('%s*$', ''), ' '))
          if path then
            git_status[require('fyler.lib.path').toabsolute(path)] = raw_status
          end
        end

        state.set({ 'git_status' }, git_status)
        state.get({ 'node', state.get { 'cwd' } }):totext():trim():render(state.get({ 'window', 'main' }).bufnr)
      end)
    end
  end)
end

return M

local util = require("fyler.lib.util")

local M = {}
local hooks = {}

local fn = vim.fn
local api = vim.api
local lsp = vim.lsp

-- Get attached active LSP clients
local function get_lsp_clients()
  if lsp.get_clients then
    return lsp.get_clients()
  else
    ---@diagnostic disable-next-line: deprecated
    return lsp.get_active_clients()
  end
end

hooks.on_highlights = function() end

---@param path string
function hooks.on_delete(path)
  if not path then return end

  local path_bufnr = fn.bufnr(path)
  if path_bufnr == -1 then return end
  path_bufnr = path_bufnr == 0 and api.nvim_get_current_buf() or path_bufnr

  api.nvim_buf_call(path_bufnr, function()
    for _, winid in ipairs(fn.win_findbuf(path_bufnr)) do
      api.nvim_win_call(winid, function()
        if not api.nvim_win_is_valid(winid) or api.nvim_win_get_buf(winid) ~= path_bufnr then return end

        local alternate_bufnr = fn.bufnr("#")
        if alternate_bufnr ~= path_bufnr and fn.buflisted(alternate_bufnr) == 1 then
          return api.nvim_win_set_buf(winid, alternate_bufnr)
        end

        ---@diagnostic disable-next-line: param-type-mismatch
        local has_previous = pcall(vim.cmd, "bprevious")
        if has_previous and path_bufnr ~= api.nvim_win_get_buf(winid) then return end

        local new_bufnr = api.nvim_create_buf(true, false)
        api.nvim_win_set_buf(winid, new_bufnr)
      end)
    end

    if api.nvim_buf_is_valid(path_bufnr) then
      ---@diagnostic disable-next-line: param-type-mismatch
      pcall(vim.cmd, "bdelete! " .. path_bufnr)
    end
  end)
end

---@param src string
---@param dst string
function hooks.on_rename(src, dst)
  if not src then return end
  if not dst then return end

  local changes = {
    files = {
      {
        oldUri = vim.uri_from_fname(src),
        newUri = vim.uri_from_fname(dst),
      },
    },
  }

  local clients = get_lsp_clients()
  for _, client in ipairs(clients) do
    if client:supports_method("workspace/willRenameFiles") then
      local response = client:request_sync("workspace/willRenameFiles", changes, 1000, 0)
      if response and response.result ~= nil then
        lsp.util.apply_workspace_edit(response.result, client.offset_encoding)
      end
    end
  end

  local src_bufnr = fn.bufnr(src)
  if src_bufnr >= 0 then
    local dst_bufnr = fn.bufadd(dst)
    util.set_buf_option(dst_bufnr, "buflisted", true)

    for _, winid in ipairs(fn.win_findbuf(src_bufnr)) do
      api.nvim_win_call(winid, function() vim.cmd("buffer " .. dst_bufnr) end)
    end

    api.nvim_buf_delete(src_bufnr, { force = true })
  end

  for _, client in ipairs(clients) do
    if client:supports_method("workspace/didRenameFiles") then client:notify("workspace/didRenameFiles", changes) end
  end
end

function M.setup(config)
  for name, fn in pairs(hooks) do
    M[name] = config.values.hooks[name] or fn
  end
end

return M

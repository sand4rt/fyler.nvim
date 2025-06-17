local M = {}

local did_setup = false

---@param opts FylerConfig
function M.setup(opts)
  if did_setup then
    return
  end

  local config = require("fyler.config")
  local autocmds = require("fyler.autocmds")
  local colors = require("fyler.lib.hls")

  M.augroup = vim.api.nvim_create_augroup("Fyler", { clear = true })
  M.config = config
  M.colors = colors
  M.aucmds = autocmds

  M.config.setup(opts)
  M.colors.setup()
  M.aucmds.setup()

  did_setup = true
end

---@param opts? FylerTreeViewOpenOpts
function M.open(opts)
  opts = opts or {}

  require("fyler.views.file_tree").open {
    cwd = opts.cwd,
    kind = opts.kind,
    config = M.config,
  }
end

function M.complete(arglead, cmdline)
  if arglead:find("^kind=") then
    return {
      "kind=split:left",
      "kind=split:above",
      "kind=split:right",
      "kind=split:below",
    }
  end

  if arglead:find("^cwd=") then
    return {
      "cwd=" .. (vim.uv or vim.loop).cwd(),
    }
  end

  return vim.tbl_filter(function(arg)
    return cmdline:match(arg) == nil
  end, {
    "kind=",
    "cwd=",
  })
end

return M

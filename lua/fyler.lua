local M = {}

local did_setup = false

---@param opts FylerConfig
function M.setup(opts)
  if did_setup then
    return
  end

  M.config = require("fyler.config")
  M.config.setup(opts)

  did_setup = true
end

---@param opts FylerTreeViewOpenOpts
function M.open(opts)
  require("fyler.views.tree").new(M.config):open(opts)
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

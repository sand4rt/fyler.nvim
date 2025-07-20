vim.api.nvim_create_user_command("Fyler", function(args)
  local opts = {}
  for _, farg in ipairs(args.fargs) do
    local key, value = unpack(vim.split(farg, "="))
    opts[key] = value
  end

  require("fyler").open(opts)
end, {
  nargs = "*",
  complete = function(arglead, cmdline)
    if arglead:find("^kind=") then
      return {
        "kind=float",
        "kind=split:left",
        "kind=split:above",
        "kind=split:right",
        "kind=split:below",
        "kind=split:leftmost",
        "kind=split:abovemost",
        "kind=split:rightmost",
        "kind=split:belowmost",
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
  end,
})

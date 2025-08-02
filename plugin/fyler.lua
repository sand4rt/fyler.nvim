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
      return vim
        .iter(vim.tbl_keys(require("fyler.config").values.views.explorer.win.kind_presets))
        :map(function(kind_preset) return string.format("kind=%s", kind_preset) end)
        :totable()
    end

    if arglead:find("^cwd=") then return { "cwd=" .. (vim.uv or vim.loop).cwd() } end

    return vim.tbl_filter(function(arg) return cmdline:match(arg) == nil end, {
      "kind=",
      "cwd=",
    })
  end,
})

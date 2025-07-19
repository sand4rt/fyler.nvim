local Ui = require("fyler.lib.ui")
local config = require("fyler.config")

local api = vim.api
local fn = vim.fn

---@alias FylerWinKind
---| "float"
---| "split:left"
---| "split:above"
---| "split:right"
---| "split:below"
---| "split:leftmost"
---| "split:abovemost"
---| "split:rightmost"
---| "split:belowmost"

---@class FylerWin
---@field augroup       string          - Autogroup associated with window instance
---@field autocmds      table           - Autocommands locally associated with window instance
---@field border        string|string[] - Border format - read ':winborder' for more info
---@field bufname       string          - Builtin way to name neovim buffers
---@field bufnr?        integer         - Buffer number associated with window instance
---@field bufopts       table           - Buffer local options
---@field enter         boolean         - whether to enter in the window on open
---@field footer?       any             - Footer content
---@field footer_pos?   string          - Footer alignment
---@field kind          FylerWinKind    - Decides launch behaviour of window instance
---@field mappings      table           - Kemaps local to the window instance
---@field name          string          - Also know as `view_name` which helps to get specific config from user end
---@field namespace     integer         - Namespace associated with window instance
---@field render?       function        - Defines what to render on the screen on open
---@field title?        any             - Title content
---@field title_pos?    string          - Title alignment
---@field ui            FylerUi         - Ui responsible to render lines return from corresponding render function
---@field user_autocmds table           - User autocommands associated with window instance
---@field winid?        integer         - Window id associated with window instance
---@field winopts       table           - Window local options
local Win = {}
Win.__index = Win

-- Prepares namespace ID by attaching buffer's given name
---@param name string
local function get_namespace(name)
  return api.nvim_create_namespace("Fyler" .. name)
end

-- Prepares autogroup ID by attaching buffer's given name
---@param name string
local function get_augroup(name)
  return api.nvim_create_augroup("Fyler" .. name, { clear = true })
end

local M = setmetatable({}, {
  ---@return FylerWin
  __call = function(_, opts)
    opts = opts or {}

    assert(opts.name, "name is required field")
    assert(opts.bufname, "bufname is required field")

    -- stylua: ignore start
    local instance = {
      augroup        = get_augroup(opts.name),
      autocmds       = opts.autocmds or {},
      bufname        = opts.bufname,
      bufopts        = opts.bufopts or {},
      enter          = opts.enter or false,
      footer         = opts.footer,
      footer_pos     = opts.footer_pos,
      kind           = opts.kind or "float",
      mappings       = opts.mappings or {},
      name           = opts.name or "",
      namespace      = get_namespace(opts.name),
      render         = opts.render,
      title          = opts.title,
      title_pos      = opts.title_pos,
      user_autocmds  = opts.user_autocmds or {},
      winopts        = opts.winopts or {},
    }
    -- stylua: ignore end

    instance.ui = Ui(instance)
    setmetatable(instance, Win)

    return instance
  end,
})

-- Determine whether the `Win` has valid buffer
---@return boolean
function Win:has_valid_bufnr()
  return type(self.bufnr) == "number" and api.nvim_buf_is_valid(self.bufnr)
end

-- Determine whether the `Win` has valid window
---@return boolean
function Win:has_valid_winid()
  return type(self.winid) == "number" and api.nvim_win_is_valid(self.winid)
end

---@return boolean
function Win:is_visible()
  return self:has_valid_bufnr() and self:has_valid_winid()
end

-- Construct respective window config in vim understandable format
---@return vim.api.keyset.win_config
function Win:config()
  local winconfig = {
    style = "minimal",
    noautocmd = true,
    title = self.title,
    title_pos = self.title_pos,
    footer = self.footer,
    footer_pos = self.footer_pos,
  }

  if self.kind:match("^split:*") then
    winconfig.split = self.kind:match("^split:(.*)")
  end

  local win = config.get_view(self.name) or { width = 0.5, height = 0.5 }

  if self.kind == "float" then
    winconfig.relative = "editor"
    winconfig.border = win.border
    winconfig.col = math.floor((1 - win.width) * 0.5 * vim.o.columns)
    winconfig.row = math.floor((1 - win.height) * 0.5 * vim.o.lines)
  end

  winconfig.width = math.ceil(win.width * vim.o.columns)
  winconfig.height = math.ceil(win.height * vim.o.lines)

  return winconfig
end

function Win:show()
  if self:has_valid_winid() then
    return
  end

  local win_config = self:config()
  if win_config.split and win_config.split:match("^%w+most$") then
    if win_config.split == "leftmost" then
      fn.execute("topleft vnew")
    elseif win_config.split == "abovemost" then
      fn.execute("topleft new")
    elseif win_config.split == "rightmost" then
      fn.execute("botright vnew")
    elseif win_config.split == "belowmost" then
      fn.execute("botright new")
    else
      error(string.format("Invalid window kind `%s`", win_config.split))
    end

    self.bufnr = api.nvim_get_current_buf()
    self.winid = api.nvim_get_current_win()
  else
    self.bufnr = api.nvim_create_buf(false, true)
    self.winid = api.nvim_open_win(self.bufnr, self.enter, win_config)
  end

  if self.render then
    self.ui:render(self.render())
  end

  api.nvim_buf_set_name(self.bufnr, self.bufname)

  for mode, map in pairs(self.mappings) do
    for key, val in pairs(map) do
      vim.keymap.set(mode, key, val, { buffer = self.bufnr, silent = true, noremap = true })
    end
  end

  for key, val in pairs(self.winopts) do
    vim.wo[self.winid][key] = val
  end

  for key, val in pairs(self.bufopts) do
    vim.bo[self.bufnr][key] = val
  end

  for ev, cb in pairs(self.autocmds) do
    api.nvim_create_autocmd(ev, {
      group = self.augroup,
      buffer = self.bufnr,
      callback = cb,
    })
  end

  for ev, cb in pairs(self.user_autocmds) do
    api.nvim_create_autocmd("User", {
      pattern = ev,
      group = self.augroup,
      callback = cb,
    })
  end
end

function Win:hide()
  if self:has_valid_winid() then
    api.nvim_win_close(self.winid, true)
  end

  if self:has_valid_bufnr() then
    api.nvim_buf_delete(self.bufnr, { force = true })
  end
end

return M

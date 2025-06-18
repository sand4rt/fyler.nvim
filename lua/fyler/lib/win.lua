local Ui = require("fyler.lib.ui")
local config = require("fyler.config")

local api = vim.api

---@alias FylerWinKind
---| "float"
---| "split:left"
---| "split:above"
---| "split:right"
---| "split:below"

---@class FylerWin
---@field ui            FylerUi
---@field open          boolean
---@field name          string
---@field kind          FylerWinKind
---@field enter         boolean
---@field bufnr?        integer
---@field winid?        integer
---@field border        string|string[]
---@field render?       fun(): FylerUi
---@field bufopts       table
---@field winopts       table
---@field augroup       string
---@field mappings      table
---@field autocmds      table
---@field namespace     integer
---@field user_autocmds table
local Win = {}
Win.__index = Win

---@param name string
local function get_namespace(name)
  return api.nvim_create_namespace("Fyler" .. name)
end

---@param name string
local function get_augroup(name)
  return api.nvim_create_augroup("Fyler" .. name, { clear = true })
end

---@class FylerWinOpts
---@field name           string
---@field kind           FylerWinKind
---@field enter          boolean
---@field render?        fun(): FylerUiLine[]
---@field bufopts?       table
---@field winopts?       table
---@field mappings?      table
---@field autocmds?      table
---@field user_autocmds? table

---@param opts FylerWinOpts
---@return FylerWin
function Win.new(opts)
  opts = opts or {}

  assert(opts.name, "name is required field")
  assert(opts.kind, "kind is required field")
  assert(opts.mappings, "mappings is required field")

  -- stylua: ignore start
  local instance = {
    open           = false,
    name           = opts.name,
    kind           = opts.kind,
    enter          = opts.enter,
    render         = opts.render,
    augroup        = get_augroup(opts.name),
    mappings       = opts.mappings or {},
    autocmds       = opts.autocmds or {},
    bufopts        = opts.bufopts or {},
    winopts        = opts.winopts or {},
    namespace      = get_namespace(opts.name),
    user_autocmds  = opts.user_autocmds or {},
  }
  -- stylua: ignore end

  instance.ui = Ui.new(instance)
  setmetatable(instance, Win)

  return instance
end

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

-- Construct respective window config in vim understandable format
---@return vim.api.keyset.win_config
function Win:config()
  local winconfig = {
    -- Shared options common for most usecases
    style = "minimal",
    noautocmd = true,
  }

  -- Split specific options
  if self.kind:match("^split:*") then
    winconfig.split = self.kind:match("^split:(.*)")
  end

  local win = config.get_view(self.name)

  -- Float specific options
  if self.kind == "float" then
    -- `relative` field is necessary for float window
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
  -- Check if window is already open
  if self:has_valid_winid() then
    return
  end

  -- Create a new buffer and open with window
  self.bufnr = api.nvim_create_buf(false, true)
  self.winid = api.nvim_open_win(self.bufnr, self.enter, self:config())

  -- Call render as soon as window open
  if self.render then
    self.ui:render(self.render())
  end

  api.nvim_buf_set_name(self.bufnr, self.name)

  -- Setup keyamps
  for mode, map in pairs(self.mappings) do
    for key, val in pairs(map) do
      vim.keymap.set(mode, key, val, { buffer = self.bufnr, silent = true, noremap = true })
    end
  end

  -- Setup buffer and window options
  for key, val in pairs(self.winopts) do
    vim.wo[self.winid][key] = val
  end

  for key, val in pairs(self.bufopts) do
    vim.bo[self.bufnr][key] = val
  end

  -- Setup autocommands
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
  -- check before closing window
  if self:has_valid_winid() then
    api.nvim_win_close(self.winid, true)
  end

  -- check before deleting buffer
  if self:has_valid_bufnr() then
    api.nvim_buf_delete(self.bufnr, { force = true })
  end
end

return Win

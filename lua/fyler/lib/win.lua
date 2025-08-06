local Ui = require("fyler.lib.ui")

---@alias FylerWinKind
---| "float"
---| "split_above"
---| "split_above_all"
---| "split_below"
---| "split_below_all"
---| "split_left"
---| "split_left_most"
---| "split_right"
---| "split_right_most"

---@class FylerWin
---@field augroup string
---@field autocmds table
---@field border string|string[]
---@field bufname string
---@field bufnr integer|nil
---@field buf_opts table
---@field enter boolean
---@field footer string|string[]|nil
---@field footer_pos string|nil
---@field height number
---@field kind FylerWinKind
---@field mappings table
---@field name string
---@field namespace integer
---@field render function|nil
---@field title string|string[]|nil
---@field title_pos string|nil
---@field ui FylerUi
---@field user_autocmds table
---@field width number
---@field winid integer|nil
---@field win_opts table
local Win = {}
Win.__index = Win

local api = vim.api
local fn = vim.fn

---@param name string
local function get_namespace(name) return api.nvim_create_namespace("Fyler" .. name) end

---@param name string
local function get_augroup(name) return api.nvim_create_augroup("Fyler" .. name, { clear = true }) end

---@return FylerWin
function Win.new(opts)
  opts = opts or {}

  assert(opts.name, "name is required field")

  -- stylua: ignore start
  local instance = {
    augroup       = get_augroup(opts.name),
    autocmds      = opts.autocmds or {},
    border        = opts.border,
    bufname       = opts.bufname,
    buf_opts      = opts.buf_opts or {},
    enter         = opts.enter,
    footer        = opts.footer,
    footer_pos    = opts.footer_pos,
    height        = opts.height,
    kind          = opts.kind or "float",
    mappings      = opts.mappings or {},
    name          = opts.name or "",
    namespace     = get_namespace(opts.name),
    render        = opts.render,
    title         = opts.title,
    title_pos     = opts.title_pos,
    user_autocmds = opts.user_autocmds or {},
    width         = opts.width,
    win_opts      = opts.win_opts or {},
  }
  -- stylua: ignore end

  instance.ui = Ui.new(instance)
  setmetatable(instance, Win)

  return instance
end

---@return boolean
function Win:has_valid_winid() return type(self.winid) == "number" and api.nvim_win_is_valid(self.winid) end

---@return boolean
function Win:has_valid_bufnr() return type(self.bufnr) == "number" and api.nvim_buf_is_valid(self.bufnr) end

function Win:is_visible()
  local buffer_in_window = #fn.win_findbuf(self.bufnr) > 0
  local window_in_tabpage = vim.tbl_contains(api.nvim_tabpage_list_wins(0), self.winid)

  return buffer_in_window and window_in_tabpage
end

function Win:focus()
  local windows = fn.win_findbuf(self.bufnr)

  if not windows or not windows[1] then return end

  fn.win_gotoid(windows[1])
end

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

  if self.kind:match("^split_") then
    winconfig.split = self.kind:match("^split_(.*)")
    winconfig.title = nil
    winconfig.title_pos = nil
    winconfig.footer = nil
    winconfig.footer_pos = nil
  elseif self.kind:match("^float") then
    winconfig.relative = "editor"
    winconfig.border = self.border
    winconfig.col = math.floor((1 - self.width) * 0.5 * vim.o.columns)
    winconfig.row = math.floor((1 - self.height) * 0.5 * vim.o.lines)
  else
    error(string.format("(fyler.nvim) Invalid window kind `%s`", self.kind))
  end

  if self.width then winconfig.width = math.ceil(self.width * vim.o.columns) end

  if self.height then winconfig.height = math.ceil(self.height * vim.o.lines) end

  return winconfig
end

function Win:show()
  if self:has_valid_winid() then return end

  local recent_win = api.nvim_get_current_win()
  local win_config = self:config()

  self.bufnr = api.nvim_create_buf(false, true)

  if self.bufname then api.nvim_buf_set_name(self.bufnr, self.bufname) end

  if win_config.split and (win_config.split:match("_all$") or win_config.split:match("_most$")) then
    if win_config.split == "left_most" then
      api.nvim_command(string.format("topleft %dvsplit", win_config.width))
    elseif win_config.split == "above_all" then
      api.nvim_command(string.format("topleft %dsplit", win_config.height))
    elseif win_config.split == "right_most" then
      api.nvim_command(string.format("botright %dvsplit", win_config.width))
    elseif win_config.split == "below_all" then
      api.nvim_command(string.format("botright %dsplit", win_config.height))
    else
      error(string.format("Invalid window kind `%s`", win_config.split))
    end

    self.winid = api.nvim_get_current_win()

    if not self.enter then api.nvim_set_current_win(recent_win) end

    api.nvim_win_set_buf(self.winid, self.bufnr)
  else
    self.winid = api.nvim_open_win(self.bufnr, self.enter, win_config)
  end

  api.nvim_exec_autocmds("User", {
    pattern = "FylerWinOpen",
    data = { win = self.winid, buf = self.bufnr, bufname = self.bufname },
  })

  for key, val in pairs(self.mappings) do
    vim.keymap.set("n", key, val, { buffer = self.bufnr, silent = true, noremap = true })
  end

  for option, value in pairs(self.win_opts) do
    vim.w[self.winid][option] = vim.wo[self.winid][option]
    vim.wo[self.winid][option] = value
  end

  for option, value in pairs(self.buf_opts) do
    vim.bo[self.bufnr][option] = value
  end

  for event, callback in pairs(self.autocmds) do
    api.nvim_create_autocmd(event, { group = self.augroup, buffer = self.bufnr, callback = callback })
  end

  for event, callback in pairs(self.user_autocmds) do
    api.nvim_create_autocmd("User", { pattern = event, group = self.augroup, callback = callback })
  end

  if self.render then self.render() end
end

function Win:hide()
  if self:has_valid_winid() then api.nvim_win_close(self.winid, true) end

  if self:has_valid_bufnr() then api.nvim_buf_delete(self.bufnr, { force = true }) end
end

return Win

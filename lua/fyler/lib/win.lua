local Ui = require("fyler.lib.ui")
local util = require("fyler.lib.util")

---@alias FylerWinKind
---| "float"
---| "replace"
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
---@field bottom string|nil
---@field buf_opts table
---@field bufname string
---@field bufnr integer|nil
---@field enter boolean
---@field footer string|string[]|nil
---@field footer_pos string|nil
---@field height string
---@field kind FylerWinKind
---@field left string|nil
---@field mappings table
---@field name string
---@field namespace integer
---@field old_bufnr integer|nil
---@field old_winid integer|nil
---@field render function|nil
---@field right string|nil
---@field title string|string[]|nil
---@field title_pos string|nil
---@field top string|nil
---@field ui FylerUi
---@field user_autocmds table
---@field width string
---@field win_opts table
---@field winid integer|nil
local Win = {}
Win.__index = Win

local api = vim.api
local fn = vim.fn

---@param name string
---@return integer
local function get_namespace(name) return api.nvim_create_namespace("Fyler" .. name) end

---@param name string
---@return integer
local function get_augroup(name) return api.nvim_create_augroup("Fyler" .. name, { clear = true }) end

---@return FylerWin
function Win.new(opts)
  opts = opts or {}

  assert(opts.name, "name is required field")

  -- stylua: ignore start
  local instance = util.tbl_merge_keep(opts, {
    augroup       = get_augroup(opts.name),
    autocmds      = {},
    buf_opts      = {},
    kind          = "float",
    mappings      = {},
    name          = "",
    namespace     = get_namespace(opts.name),
    user_autocmds = {},
    win_opts      = {},
  })
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

  api.nvim_set_current_win(windows[1])
end

function Win:config()
  local winconfig = {
    style = "minimal",
  }

  ---@param str string
  local function destructure(str)
    if not str:match("[%d%.]+[%a]+") then return 0, 0 end
    local v, u = string.match(str, "([%d%.]+)([%a]+)")
    return tonumber(v), u
  end

  if self.kind:match("^split_") then
    winconfig.split = self.kind:match("^split_(.*)")
  elseif self.kind:match("^replace") then
    return winconfig
  elseif self.kind:match("^float") then
    winconfig.relative = "editor"
    winconfig.border = self.border
    winconfig.title = self.title
    winconfig.title_pos = self.title_pos
    winconfig.footer = self.footer
    winconfig.footer_pos = self.footer_pos
    winconfig.row = 0
    winconfig.col = 0

    if self.top and self.top ~= "none" then
      local value, unit = destructure(self.top)
      if unit == "rel" then
        winconfig.row = math.ceil(value * vim.o.lines)
      elseif unit == "abs" then
        winconfig.row = value
      else
        error(string.format("(fyler.nvim) Unknown unit '%s'", unit))
      end
    end

    if self.right and self.right ~= "none" then
      local rv, ru = destructure(self.right)
      local wv = destructure(self.width)
      if ru == "rel" then
        winconfig.col = math.ceil((1 - rv - wv) * vim.o.columns)
      elseif ru == "abs" then
        winconfig.col = (vim.o.columns - rv - wv)
      else
        error(string.format("(fyler.nvim) Unknown unit '%s'", ru))
      end
    end

    if self.bottom and self.bottom ~= "none" then
      local value, unit = destructure(self.bottom)
      local hv = destructure(self.height)
      if unit == "rel" then
        winconfig.row = math.ceil((1 - value - hv) * vim.o.lines)
      elseif unit == "abs" then
        winconfig.row = (vim.o.lines - value - hv)
      else
        error(string.format("(fyler.nvim) Unknown unit '%s'", unit))
      end
    end

    if self.left and self.left ~= "none" then
      local value, unit = destructure(self.left)
      if unit == "rel" then
        winconfig.col = math.ceil(value * vim.o.columns)
      elseif unit == "abs" then
        winconfig.col = value
      else
        error(string.format("(fyler.nvim) Unknown unit '%s'", unit))
      end
    end
  else
    error(string.format("(fyler.nvim) Invalid window kind `%s`", self.kind))
  end

  if self.width then
    local value, unit = destructure(self.width)
    if unit == "rel" then
      winconfig.width = math.ceil(value * vim.o.columns)
    elseif unit == "abs" then
      winconfig.width = value
    else
      error(string.format("(fyler.nvim) Unknown unit '%s'", unit))
    end
  end

  if self.height then
    local value, unit = destructure(self.height)
    if unit == "rel" then
      winconfig.height = math.ceil(value * vim.o.lines)
    elseif unit == "abs" then
      winconfig.height = value
    else
      error(string.format("(fyler.nvim) Unknown unit '%s'", unit))
    end
  end

  return winconfig
end

function Win:show()
  if self:has_valid_winid() then return end

  -- Saving alternative "bufnr" and "winid" for later use
  self.old_bufnr = api.nvim_get_current_buf()
  self.old_winid = api.nvim_get_current_win()
  self.bufnr = api.nvim_create_buf(false, true)
  if self.bufname then api.nvim_buf_set_name(self.bufnr, self.bufname) end

  local win_config = self:config()
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
    if not self.enter then api.nvim_set_current_win(self.old_winid) end

    api.nvim_win_set_buf(self.winid, self.bufnr)
  elseif self.kind:match("^replace") then
    self.winid = vim.api.nvim_get_current_win()
    api.nvim_win_set_buf(self.winid, self.bufnr)
  else
    self.winid = api.nvim_open_win(self.bufnr, self.enter, win_config)

    -- Trigger "BufEnter" event to focus buffer for floating window when "enter" enabled
    -- [IMPORTANT]: This is necessary because "self.winid" will not get set on time to automatically triggered.
    if self.enter then vim.api.nvim_exec_autocmds("BufEnter", {}) end
  end

  api.nvim_exec_autocmds("User", {
    pattern = "FylerWinOpen",
    data = { win = self.winid, buf = self.bufnr, bufname = self.bufname },
  })

  for k, v in pairs(self.mappings) do
    vim.keymap.set("n", k, v, { buffer = self.bufnr, silent = true, noremap = true })
  end

  for option, value in pairs(self.win_opts) do
    util.set_win_option(self.winid, option, value)
  end

  for option, value in pairs(self.buf_opts) do
    util.set_buf_option(self.bufnr, option, value)
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
  -- Recover alternate buffer if using "replace"|"split" window kind
  if self.kind:match("^replace") then
    if
      util.is_valid_winid(self.winid)
      and util.is_valid_bufnr(self.old_bufnr)
      and api.nvim_buf_is_loaded(self.old_bufnr)
    then
      api.nvim_win_set_buf(self.winid, self.old_bufnr)
    end

    util.try(api.nvim_buf_delete, self.bufnr, { force = true })
  else
    util.try(api.nvim_win_close, self.winid, true)
    util.try(api.nvim_buf_delete, self.bufnr, { force = true })
  end

  self.winid = nil
  self.bufnr = nil
end

-- Handle case when user open a NON FYLER BUFFER in "Fyler" window
function Win:recover()
  if self.kind:match("^replace") or self.kind:match("^split") then
    util.try(api.nvim_buf_delete, self.bufnr, { force = true })
  else
    local cached_bufnr = api.nvim_get_current_buf()
    util.try(api.nvim_win_close, self.winid, true)
    util.try(api.nvim_buf_delete, self.bufnr, { force = true })

    if util.is_valid_winid(self.old_winid) then
      api.nvim_win_set_buf(self.old_winid, cached_bufnr)
      api.nvim_set_current_win(self.old_winid)
    end
  end
end

return Win

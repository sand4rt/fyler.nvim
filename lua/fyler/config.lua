local util = require "fyler.lib.util"

---@class FylerConfigHooks
---@field on_delete fun(path: string)|nil
---@field on_rename fun(src: string, dst: string)|nil
---@field on_highlight fun(groups: table, palette: Palette)|nil

---@alias FylerConfigIconProvider
---| "mini_icons"
---| "none"
---| "nvim_web_devicons"

---@alias FylerConfigExplorerMapping
---| "CloseView"
---| "GotoCwd"
---| "GotoNode"
---| "GotoParent"
---| "Select"
---| "SelectSplit"
---| "SelectTab"
---| "SelectVSplit"

---@class FylerConfigIndentScope
---@field enabled boolean
---@field group string
---@field marker string

---@alias FylerConfigWinBorder
---| "bold"
---| "double"
---| "none"
---| "rounded"
---| "shadow"
---| "single"
---| "solid"

---@class FylerConfigWin
---@field border FylerConfigWinBorder|string[]
---@field buf_opts table
---@field kind WinKind
---@field kind_presets table<WinKind|string, table>
---@field win_opts table

---@class FylerConfig
---@field hooks FylerConfigHooks
---@field icon_provider FylerConfigIconProvider
---@field mappings table<string, FylerConfigExplorerMapping>
---@field close_on_select boolean
---@field confirm_simple boolean
---@field default_explorer boolean
---@field git_status boolean
---@field indentscope FylerConfigIndentScope
---@field track_current_buffer boolean
---@field win FylerConfigWin

local M = {}

---@return FylerConfig
local function defaults()
  return {
    hooks = {
      on_delete = nil,
      on_rename = nil,
      on_highlight = nil,
    },
    icon_provider = "mini_icons",
    mappings = {
      ["q"] = "CloseView",
      ["<CR>"] = "Select",
      ["<C-t>"] = "SelectTab",
      ["|"] = "SelectVSplit",
      ["-"] = "SelectSplit",
      ["^"] = "GotoParent",
      ["="] = "GotoCwd",
      ["."] = "GotoNode",
    },
    close_on_select = true,
    confirm_simple = false,
    default_explorer = false,
    git_status = true,
    indentscope = {
      enabled = true,
      group = "FylerIndentMarker",
      marker = "│",
    },
    track_current_buffer = true,
    win = {
      border = "single",
      buf_opts = {
        filetype = "fyler",
        syntax = "fyler",
        buflisted = false,
        buftype = "acwrite",
        expandtab = true,
        shiftwidth = 2,
      },
      kind = "replace",
      kind_presets = {
        float = {
          height = "0.7rel",
          width = "0.7rel",
          top = "0.1rel",
          left = "0.15rel",
        },
        replace = {},
        split_above = {
          height = "0.7rel",
        },
        split_above_all = {
          height = "0.7rel",
        },
        split_below = {
          height = "0.7rel",
        },
        split_below_all = {
          height = "0.7rel",
        },
        split_left = {
          width = "0.3rel",
        },
        split_left_most = {
          width = "0.3rel",
        },
        split_right = {
          width = "0.3rel",
        },
        split_right_most = {
          width = "0.3rel",
        },
      },
      win_opts = {
        concealcursor = "nvic",
        conceallevel = 3,
        cursorline = true,
        number = true,
        relativenumber = true,
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,FloatTitle:FloatTitle",
        wrap = false,
      },
    },
  }
end

function M.get_reversed_maps()
  local reversed_maps = {}
  for k, v in pairs(M.values.mappings) do
    if v then reversed_maps[v] = k end
  end

  setmetatable(reversed_maps, { __index = function() return "<nop>" end })

  return reversed_maps
end

-- Type check for configuration option
---@param name string
---@param value any
---@param ref string|string[]
---@param allow_nil boolean|nil
local function check_type(name, value, ref, allow_nil)
  local are_matched = (function()
    if type(ref) == "table" then
      return util.if_any(ref, function(x) return type(value) == x end)
    elseif type(value) == ref then
      return true
    else
      return false
    end
  end)()

  if are_matched or (ref == "callable" and vim.is_callable(value)) or (allow_nil and value == nil) then return end

  error(string.format("(fyler.nvim) `%s` should be %s, not %s", name, ref, type(value)))
end

-- Overwrites the defaults configuration options with user options
function M.setup(opts)
  opts = opts or {}
  check_type("config", opts, "table")

  M.values = util.tbl_merge_force(defaults(), opts)

  local checks = {
    { "config.hooks", M.values.hooks, "table" },
    { "config.hooks.on_delete", M.values.hooks.on_delete, "function", true },
    { "config.hooks.on_rename", M.values.hooks.on_rename, "function", true },
    { "config.hooks.on_highlights", M.values.hooks.on_highlight, "function", true },
    { "config.icon_provider", M.values.icon_provider, { "string", "function" } },
    { "config.mappings", M.values.mappings, "table" },
    { "config.close_on_select", M.values.close_on_select, "boolean" },
    { "config.confirm_simple", M.values.confirm_simple, "boolean" },
    { "config.default_explorer", M.values.default_explorer, "boolean" },
    { "config.git_status", M.values.git_status, "boolean" },
    { "config.indentscope", M.values.indentscope, "table" },
    { "config.track_current_buffer", M.values.track_current_buffer, "boolean" },
    { "config.win", M.values.win, "table" },
  }

  for _, check in ipairs(checks) do
    check_type(util.unpack(check))
  end
end

return M

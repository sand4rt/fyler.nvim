---Defines icon provider to various views. It is a function with following definition:
---```
---fun(type: string, name: string): string, string
---```
---Builtin options: `mini-icons`, `nvim-web-devicons`
---@alias FylerConfigIconProvider "mini-icons" | "nvim-web-devicons" | fun(type: string, name: string): string, string

---@class FylerConfigIndentScope
---@field enabled boolean Enable or disable indentation markers
---@field group   string  Change highlight group
---@field marker  string  Change marker char

---@alias FylerConfigMappingsExplorer
---| "CloseView" Close explorer view
---| "Select"    Select item under the cursor
---| false       Disable keymap

---@alias FylerConfigMappingsConfirm
---| "Confirm" Confirm actions
---| "Discard" Discard actions
---| false     Disable keymap

---@class FylerConfigMappings
---@field confirm  table<string, FylerConfigMappingsConfirm>
---@field explorer table<string, FylerConfigMappingsExplorer>

---@alias FylerConfigViewWinKindPreset { height: number, width: number }

---@class FylerConfigViewWin
---@field border       string                                      Window border style (for more info ':help winborder')
---@field buf_opts     table<string, any>                          Buffer options
---@field kind         FylerWinKind                                Window kind
---@field kind_presets table<string, FylerConfigViewWinKindPreset> Window kind
---@field win_opts     table<string, any>                          Window options

---@class FylerConfigViewConfirm
---@field win  FylerConfigViewWin

---@class FylerConfigViewExplorer
---@field close_on_select  boolean
---@field confirm_simple   boolean
---@field default_explorer boolean
---@field git_status       boolean
---@field indentscope      FylerConfigIndentScope
---@field win              FylerConfigViewWin

---@class FylerConfigViews
---@field confirm  FylerConfigViewConfirm
---@field explorer FylerConfigViewExplorer

---@class FylerConfigDefaults
---@field icon_provider FylerConfigIconProvider
---@field mappings      FylerConfigMappings
---@field on_highlights fun(groups: table, palette: table): nil  How to change highlight groups
---@field views         FylerConfigViews

---@class FylerConfig : FylerConfigDefaults
---@field icon_provider? FylerConfigIconProvider
---@field mappings?      FylerConfigMappings
---@field on_highlights? fun(groups: table, palette: table): nil
---@field views?         FylerConfigViews

local M = {}

---@type FylerConfigDefaults
local defaults = {
  icon_provider = "mini-icons",
  mappings = {
    explorer = {
      ["q"] = "CloseView",
      ["<CR>"] = "Select",
    },
    confirm = {
      ["y"] = "Confirm",
      ["n"] = "Discard",
    },
  },
  on_highlights = function() end,
  views = {
    confirm = {
      win = {
        border = "single",
        buf_opts = {
          buflisted = false,
          modifiable = false,
        },
        kind = "float",
        kind_presets = {
          float = {
            height = 0.4,
            width = 0.5,
          },
          split_above = {
            height = 0.5,
          },
          split_above_all = {
            height = 0.5,
          },
          split_below = {
            height = 0.5,
          },
          split_below_all = {
            height = 0.5,
          },
          split_left = {
            width = 0.5,
          },
          split_left_most = {
            width = 0.5,
          },
          split_right = {
            width = 0.5,
          },
          split_right_most = {
            width = 0.5,
          },
        },
        win_opts = {
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder,FloatTitle:FloatTitle",
          wrap = false,
        },
      },
    },
    explorer = {
      close_on_select = true,
      confirm_simple = false,
      default_explorer = false,
      git_status = true,
      indentscope = {
        enabled = true,
        group = "FylerIndentMarker",
        marker = "│",
      },
      win = {
        border = "single",
        buf_opts = {
          buflisted = false,
          buftype = "acwrite",
          filetype = "fyler",
          syntax = "fyler",
        },
        kind = "float",
        kind_presets = {
          float = {
            height = 0.7,
            width = 0.7,
          },
          split_above = {
            height = 0.7,
          },
          split_above_all = {
            height = 0.7,
          },
          split_below = {
            height = 0.7,
          },
          split_below_all = {
            height = 0.7,
          },
          split_left = {
            width = 0.3,
          },
          split_left_most = {
            width = 0.3,
          },
          split_right = {
            width = 0.3,
          },
          split_right_most = {
            width = 0.3,
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
    },
  },
}

---@param name  string
---@param kind? FylerWinKind
function M.get_view(name, kind)
  assert(name, "name is required")

  local view = M.values.views[name]
  local preset = view.win.kind_presets[kind or view.win.kind]
  view.win.height = preset.height
  view.win.width = preset.width

  return view
end

---@param name string
function M.get_mappings(name)
  assert(name, "name is required")

  return M.values.mappings[name]
end

---@param name string
function M.get_reverse_mappings(name)
  assert(name, "name is required")

  local mappings = M.get_mappings(name)
  local reverse_mappings = {}

  for key, val in pairs(mappings) do
    reverse_mappings[val] = key
  end

  return reverse_mappings
end

---@param name       string
---@param value      any
---@param ref        string|string[]
---@param allow_nil? boolean
local function check_type(name, value, ref, allow_nil)
  local are_matched = (function()
    if type(ref) == "table" then
      return vim.iter(ref):any(function(x)
        return type(value) == x
      end)
    elseif type(value) == ref then
      return true
    else
      return false
    end
  end)()

  if are_matched or (ref == "callable" and vim.is_callable(value)) or (allow_nil and value == nil) then
    return
  end

  error(string.format("(fyler.nvim) `%s` should be %s, not %s", name, ref, type(value)))
end

---@param config? FylerConfig
function M.setup(config)
  if config == nil then
    return
  end

  check_type("config", config, "table")

  M.values = vim.tbl_deep_extend("force", defaults, config)

  for _, view_name in ipairs {
    "confirm",
    "explorer",
  } do
    local win = M.values.views[view_name].win
    check_type(
      string.format("config.views.%s.win.kind_presets.%s", view_name, win.kind),
      win.kind_presets[win.kind],
      "table"
    )

    for _, kind_preset_name in ipairs {
      "float",
      "split_above",
      "split_above_all",
      "split_below",
      "split_below_all",
      "split_left",
      "split_left_most",
      "split_right",
      "split_right_most",
    } do
      local kind_preset = M.values.views[view_name].win.kind_presets[kind_preset_name]
      check_type(string.format("config.views.%s.%s", view_name, kind_preset_name), kind_preset, "table")
      check_type(
        string.format("config.views.%s.%s.height", view_name, kind_preset_name),
        kind_preset.height,
        "number",
        kind_preset_name ~= "float"
      )
      check_type(
        string.format("config.views.%s.%s.width", view_name, kind_preset_name),
        kind_preset.width,
        "number",
        kind_preset_name ~= "float"
      )
    end
  end

  check_type("config.icon_provider", M.values.icon_provider, { "string", "function" })
  check_type("config.mappings", M.values.mappings, "table")
  check_type("config.mappings.confirm", M.values.mappings.confirm, "table")
  check_type("config.mappings.explorer", M.values.mappings.explorer, "table")
  check_type("config.on_highlights", M.values.on_highlights, "function")
  check_type("config.views", M.values.views, "table")
  check_type("config.views.confirm", M.values.views.confirm, "table")
  check_type("config.views.confirm.kind", M.values.views.confirm.win.kind, "string")
  check_type("config.views.confirm.win.border", M.values.views.confirm.win.border, "string")
  check_type("config.views.confirm.win.buf_opts", M.values.views.confirm.win.buf_opts, "table")
  check_type("config.views.confirm.win.win_opts", M.values.views.confirm.win.win_opts, "table")
  check_type("config.views.explorer", M.values.views.explorer, "table")
  check_type("config.views.explorer.close_on_select", M.values.views.explorer.close_on_select, "boolean")
  check_type("config.views.explorer.confirm_simple", M.values.views.explorer.confirm_simple, "boolean")
  check_type("config.views.explorer.default_explorer", M.values.views.explorer.default_explorer, "boolean")
  check_type("config.views.explorer.git_status", M.values.views.explorer.git_status, "boolean")
  check_type("config.views.explorer.indentscope", M.values.views.explorer.indentscope, "table")
  check_type("config.views.explorer.indentscope.enabled", M.values.views.explorer.indentscope.enabled, "boolean")
  check_type("config.views.explorer.indentscope.group", M.values.views.explorer.indentscope.group, "string")
  check_type("config.views.explorer.indentscope.marker", M.values.views.explorer.indentscope.marker, "string")
  check_type("config.views.explorer.kind", M.values.views.explorer.win.kind, "string")
  check_type("config.views.explorer.win.border", M.values.views.explorer.win.border, "string")
  check_type("config.views.explorer.win.buf_opts", M.values.views.explorer.win.buf_opts, "table")
  check_type("config.views.explorer.win.win_opts", M.values.views.explorer.win.win_opts, "table")
end

return M

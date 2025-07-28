---@class FylerConfigView
---@field width  number
---@field height number
---@field kind   FylerWinKind
---@field border nil|string|string[]

---@class FylerConfig
---@field auto_confirm_simple_edits? boolean
---@field close_on_select?           boolean
---@field default_explorer?          boolean
---@field git_status                 boolean
---@field icon_provider?             string|fun(type: string, name: string): string, string
---@field indentscope                { enabled: boolean, group: string, marker: string }
---@field on_highlights              fun(hl_groups: table, palette: table): nil
---@field views?                     table<string, FylerConfigView>
---@field mappings?                  table<string, table<"n"|"i", table<string, string>>>

local M = {}

local defaults = {
  auto_confirm_simple_edits = false,
  close_on_select = true,
  default_explorer = false,
  git_status = true,
  icon_provider = "mini-icons",
  on_highlights = nil,
  indentscope = {
    enabled = true,
    group = "FylerIndentMarker",
    marker = "│",
  },
  mappings = {
    confirm = {
      n = {
        ["y"] = "Confirm",
        ["n"] = "Discard",
      },
    },
    explorer = {
      n = {
        ["q"] = "CloseView",
        ["<CR>"] = "Select",
      },
    },
  },
  views = {
    confirm = {
      width = 0.5,
      height = 0.4,
      kind = "float",
      border = nil,
      buf_opts = {
        buflisted = false,
        modifiable = false,
      },
      win_opts = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,FloatTitle:FloatTitle",
        wrap = false,
      },
    },
    explorer = {
      width = 0.8,
      height = 0.8,
      kind = "float",
      border = nil,
      buf_opts = {
        expandtab = true,
        buflisted = false,
        buftype = "acwrite",
        filetype = "fyler",
        syntax = "fyler",
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
}

---@param name string
function M.get_view(name)
  assert(name, "name is required")

  return M.values.views[name]
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

  for _, map in pairs(mappings) do
    for key, val in pairs(map) do
      reverse_mappings[val] = key
    end
  end

  return reverse_mappings
end

---@param opts? FylerConfig
function M.setup(opts)
  opts = opts or {}
  M.values = vim.tbl_deep_extend("force", defaults, opts)
end

return M

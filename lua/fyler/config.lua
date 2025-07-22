---@class FylerConfigView
---@field width  number
---@field height number
---@field kind   FylerWinKind
---@field border string|string[]

---@class FylerConfig
---@field close_on_select?           boolean
---@field default_explorer?          boolean
---@field git_status                 boolean
---@field icon_provider?             boolean
---@field auto_confirm_simple_edits? boolean
---@field indentscope                { enabled: boolean, group: string, marker: string }
---@field views?                     table<string, FylerConfigView>
---@field mappings?                  table<string, table<"n"|"i", table<string, string>>>

local M = {}

local defaults = {
  auto_confirm_simple_edits = false,
  close_on_select = true,
  default_explorer = false,
  git_status = true,
  icon_provider = "mini-icons",
  indentscope = {
    enabled = true,
    group = "FylerDarkGrey",
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
      border = "single",
    },
    explorer = {
      width = 0.8,
      height = 0.8,
      kind = "float",
      border = "single",
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

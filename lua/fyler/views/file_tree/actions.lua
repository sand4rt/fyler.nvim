local algos = require("fyler.views.file_tree.algos")
local config = require("fyler.config")
local confirm_view = require("fyler.views.confirm")
local fs = require("fyler.lib.fs")
local regex = require("fyler.views.file_tree.regex")
local store = require("fyler.views.file_tree.store")
local ui = require("fyler.views.file_tree.ui")

local M = {}

local fn = vim.fn
local api = vim.api

-- `view` must have close implementation
---@param view table
function M.n_close_view(view)
  return function()
    view:close()
  end
end

---@param view FylerTreeView
function M.n_select(view)
  return function()
    local key = regex.getkey(api.nvim_get_current_line())
    if not key then
      return
    end

    local meta_data = store.get(key)
    if meta_data:is_directory() then
      view.tree_node:find(key):toggle()
      api.nvim_exec_autocmds("User", { pattern = "RefreshView" })
    else
      local recent_win = require("fyler.cache").get_entry("recent_win")
      if recent_win and api.nvim_win_is_valid(recent_win) then
        fn.win_execute(recent_win, string.format("edit %s", meta_data:resolved_path()))
        fn.win_gotoid(recent_win)
        if config.values.close_on_select then
          view:close()
        end
      end
    end
  end
end

function M.n_select_recursive(view)
  return function()
    local key = regex.getkey(api.nvim_get_current_line())
    if not key then
      return
    end

    local meta_data = store.get(key)
    if meta_data:is_directory() then
      view.tree_node:find(key):toggle_recursive()
      view:refresh()
    else
      M.n_select(view)
    end
  end
end

---@param tbl table
---@return table
local function get_tbl(tbl)
  local lines = {}

  if not vim.tbl_isempty(tbl.create) then
    table.insert(lines, { { str = "# Creation", hl = "FylerGreen" } })
    for _, change in ipairs(tbl.create) do
      table.insert(lines, {
        { str = "  - " },
        { str = fs.torelpath(change), hl = "Conceal" },
      })
    end

    table.insert(lines, { { str = "" } })
  end

  if not vim.tbl_isempty(tbl.delete) then
    table.insert(lines, { { str = "# Deletetion", hl = "FylerRed" } })
    for _, change in ipairs(tbl.delete) do
      table.insert(lines, {
        { str = "  - " },
        { str = fs.torelpath(change), hl = "Conceal" },
      })
    end

    table.insert(lines, { { str = "" } })
  end

  if not vim.tbl_isempty(tbl.move) then
    table.insert(lines, { { str = "# Migration", hl = "FylerYellow" } })
    for _, change in ipairs(tbl.move) do
      table.insert(lines, {
        { str = "  - " },
        { str = fs.torelpath(change.from), hl = "Conceal" },
        { str = " > " },
        { str = fs.torelpath(change.to), hl = "Conceal" },
      })
    end

    table.insert(lines, { { str = "" } })
  end

  return lines
end

---@param view FylerTreeView
function M.n_synchronize(view)
  return function()
    local changes = algos.get_diff(view)
    confirm_view.open(get_tbl(changes), " [Y]Confirm [N]Discard ", function(c)
      if c then
        for _, change in ipairs(changes.create) do
          fs.create_fs_item(change)
        end

        for _, change in ipairs(changes.delete) do
          fs.delete_fs_item(change)
        end

        for _, change in ipairs(changes.move) do
          fs.move_fs_item(change.from, change.to)
        end
      end

      api.nvim_exec_autocmds("User", { pattern = "RefreshView" })
    end)
  end
end

---@param view FylerTreeView
function M.n_refreshview(view)
  return function()
    view.tree_node:update()
    view.win.ui:render(ui.FileTree(algos.tree_table_from_node(view).children))
    vim.bo[view.win.bufnr].syntax = "fyler"
    vim.bo[view.win.bufnr].filetype = "fyler"
  end
end

function M.constrain_cursor(view)
  return function(arg)
    local cline = api.nvim_get_current_line()
    local key = regex.getkey(cline)
    if key then
      local item_name = regex.getname(cline)
      if item_name == "" then
        return
      end

      local row, col = unpack(api.nvim_win_get_cursor(view.win.winid))
      local lb, ub = cline:find(item_name, 1, true)
      lb = lb - 1
      ub = ub - 1

      if col < lb then
        api.nvim_win_set_cursor(view.win.winid, { row, lb })
      end

      if col > ub then
        api.nvim_win_set_cursor(view.win.winid, { row, ub + (arg.event == "CursorMovedI" and 1 or 0) })
      end
    end
  end
end

return M

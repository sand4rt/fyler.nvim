local config = require("fyler.config")
local confirm_view = require("fyler.views.confirm")
local fs = require("fyler.lib.fs")
local regex = require("fyler.views.file_tree.regex")
local store = require("fyler.views.file_tree.store")

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

-- TODO: Should extend this action to handle symbolic links
---@param view FylerTreeView
function M.n_select(view)
  return function()
    local key = regex.getkey(api.nvim_get_current_line())
    if not key then
      return
    end

    local meta_data = store.get(key)
    if meta_data.type == "directory" then
      view.tree_node:find(key):toggle()
      view:refresh()
    else
      local recent_win = require("fyler.cache").get_entry("recent_win")
      if recent_win and api.nvim_win_is_valid(recent_win) then
        fn.win_execute(recent_win, string.format("edit %s", meta_data.path))
        fn.win_gotoid(recent_win)
        if config.values.close_on_select then
          view:close()
        end
      end
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
    local changes = view:get_diff()
    confirm_view(get_tbl(changes), " [Y]Confirm [N]Discard ", function(c)
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

      view:refresh()
    end)
  end
end

function M.n_refreshview(view)
  return function()
    view:refresh()
  end
end

return M

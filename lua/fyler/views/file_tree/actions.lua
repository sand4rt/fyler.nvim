local config = require("fyler.config")
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
---@return string
local function get_changes_str(tbl)
  local str = ""

  for change_type, changes in pairs(tbl) do
    for _, change in ipairs(changes) do
      if change_type == "move" then
        str = str .. string.upper(change_type) .. " " .. change.from .. " > " .. change.to .. "\n"
      else
        str = str .. string.upper(change_type) .. " " .. change .. "\n"
      end
    end

    str = str .. "\n"
  end

  return str
end

---@param view FylerTreeView
function M.n_synchronize(view)
  return function()
    local changes = view:get_diff()
    local choice = vim.fn.confirm(get_changes_str(changes), "&YConfirm\n&NDiscard")

    if choice == 1 then
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
  end
end

function M.n_refreshview(view)
  return function()
    view.win.ui:render(
      require("fyler.views.file_tree.ui").FileTree(view:update_tree():tree_table_from_node().children)
    )
  end
end

return M

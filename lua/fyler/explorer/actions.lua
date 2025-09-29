local e_util = require "fyler.explorer.util"
local util = require "fyler.lib.util"
local M = {}
local fn = vim.fn
local api = vim.api

---@param self Explorer
function M.n_close(self)
  return function()
    self:close()
  end
end

---@param self Explorer
function M.n_select(self)
  return function()
    local ref_id = e_util.parse_ref_id(api.nvim_get_current_line())
    if not ref_id then
      return
    end

    local entry = self.file_tree:node_entry(ref_id)
    if not entry then
      return
    end

    if entry:isdir() then
      if entry.open then
        self.file_tree:collapse_node(ref_id)
      else
        self.file_tree:expand_node(ref_id)
      end

      self:dispatch_refresh()
    else
      if util.is_valid_winid(self.win.old_winid) then
        if self.config.values.close_on_select then
          self:close()
        end

        api.nvim_set_current_win(self.win.old_winid)
        api.nvim_win_call(self.win.old_winid, function()
          vim.cmd.edit(vim.fn.fnameescape(entry.path))
        end)
      end
    end
  end
end

---@param self Explorer
function M.n_select_tab(self)
  return function()
    local ref_id = e_util.parse_ref_id(api.nvim_get_current_line())
    if not ref_id then
      return
    end

    local entry = self.file_tree:node_entry(ref_id)
    if not entry:isdir() then
      if util.is_valid_winid(self.win.old_winid) then
        if self.config.values.close_on_select then
          self:close()
        end

        vim.cmd.tabedit(entry.path)
      end
    end
  end
end

---@param self Explorer
function M.n_select_v_split(self)
  return function()
    local ref_id = e_util.parse_ref_id(api.nvim_get_current_line())
    if not ref_id then
      return
    end

    local entry = self.file_tree:node_entry(ref_id)
    if not entry:isdir() then
      if util.is_valid_winid(self.win.old_winid) then
        if self.config.values.close_on_select then
          self:close()
        end

        api.nvim_set_current_win(self.win.old_winid)
        vim.cmd.vsplit(entry.path)
      end
    end
  end
end

---@param self Explorer
function M.n_select_split(self)
  return function()
    local ref_id = e_util.parse_ref_id(api.nvim_get_current_line())
    if not ref_id then
      return
    end

    local entry = self.file_tree:node_entry(ref_id)
    if not entry:isdir() then
      if util.is_valid_winid(self.win.old_winid) then
        api.nvim_set_current_win(self.win.old_winid)
        if self.config.values.close_on_select then
          self:close()
        end

        api.nvim_set_current_win(self.win.old_winid)
        vim.cmd.split(entry.path)
      end
    end
  end
end

---@param self Explorer
function M.n_collapse_all(self)
  return function()
    self.file_tree:collapse_all()
    self:dispatch_refresh()
  end
end

---@param self Explorer
function M.n_goto_parent(self)
  return function()
    local current_dir = self:getcwd()
    if not current_dir then
      return
    end

    local parent_dir = fn.fnamemodify(current_dir, ":h")
    if parent_dir == self:getcwd() then
      return
    end

    self:chdir(parent_dir)
    self:dispatch_refresh()
  end
end

---@param self Explorer
function M.n_goto_cwd(self)
  return function()
    if self:getcwd() == self.dir then
      return
    end

    self:chdir(self.dir)
    self:dispatch_refresh()
  end
end

---@param self Explorer
function M.n_goto_node(self)
  return function()
    local ref_id = e_util.parse_ref_id(api.nvim_get_current_line())
    if not ref_id then
      return
    end

    local entry = self.file_tree:node_entry(ref_id)
    if not entry then
      return
    end

    if entry:isdir() then
      self:chdir(entry.path)

      self:dispatch_refresh()
    else
      M.n_select(self)()
    end
  end
end

---@param self Explorer
function M.n_collapse_node(self)
  return function()
    local ref_id = e_util.parse_ref_id(api.nvim_get_current_line())
    if not ref_id then
      return
    end

    local entry = self.file_tree:node_entry(ref_id)
    if not entry then
      return
    end

    -- should not collapse root, so get it's id
    local root_ref_id = self.file_tree.tree.root and self.file_tree.tree.root.value
    if entry:isdir() and ref_id == root_ref_id then
      return
    end

    local collapse_target = self.file_tree:find_parent(ref_id)
    if (not collapse_target) or (not entry.open) and collapse_target == root_ref_id then
      return
    end

    local focus_ref_id
    if entry:isdir() and entry.open then
      self.file_tree:collapse_node(ref_id)
      focus_ref_id = ref_id
    else
      self.file_tree:collapse_node(collapse_target)
      focus_ref_id = collapse_target
    end

    self:dispatch_refresh(function()
      if not self.win:has_valid_winid() then
        return
      end

      local marker = string.format("/%05d", focus_ref_id)
      local lines = api.nvim_buf_get_lines(self.win.bufnr, 0, -1, false)

      for ln, line in ipairs(lines) do
        if line:find(marker, 1, true) then
          api.nvim_win_set_cursor(self.win.winid, { ln, 0 })
          break
        end
      end
    end)
  end
end

return M

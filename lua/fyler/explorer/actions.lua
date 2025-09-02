local a = require "fyler.lib.async"
local eu = require "fyler.explorer.util"
local fs = require "fyler.lib.fs"
local git = require "fyler.lib.git"
local ui = require "fyler.explorer.ui"
local util = require "fyler.lib.util"

local M = {}
local fn = vim.fn
local api = vim.api

---@param self Explorer
function M.n_close(self)
  return function() self.win:hide() end
end

---@param self Explorer
function M.n_select(self)
  return function()
    local indentity = eu.parse_identity(api.nvim_get_current_line())
    if not indentity then return end

    local entry = self.file_tree:node_entry(indentity)
    if not entry then return end

    if entry:isdir() then
      if entry.open then
        self.file_tree:compress_node(indentity)
      else
        self.file_tree:expand_node(indentity)
      end

      api.nvim_exec_autocmds("User", { pattern = "DispatchRefresh" })
    else
      if util.is_valid_winid(self.win.old_winid) then
        if self.config.values.close_on_select then self.win:hide() end

        api.nvim_set_current_win(self.win.old_winid)
        api.nvim_win_call(self.win.old_winid, function() vim.cmd.edit(entry.path) end)
      end
    end
  end
end

---@param self Explorer
function M.n_select_tab(self)
  return function()
    local identity = eu.parse_identity(api.nvim_get_current_line())
    if not identity then return end

    local entry = self.file_tree:node_entry(identity)
    if not entry:isdir() then
      if util.is_valid_winid(self.win.old_winid) then
        if self.config.values.close_on_select then self.win:hide() end

        vim.cmd.tabedit(entry.path)
      end
    end
  end
end

---@param self Explorer
function M.n_select_v_split(self)
  return function()
    local identity = eu.parse_identity(api.nvim_get_current_line())
    if not identity then return end

    local entry = self.file_tree:node_entry(identity)
    if not entry:isdir() then
      if util.is_valid_winid(self.win.old_winid) then
        if self.config.values.close_on_select then self.win:hide() end

        api.nvim_set_current_win(self.win.old_winid)
        vim.cmd.vsplit(entry.path)
      end
    end
  end
end

---@param self Explorer
function M.n_select_split(self)
  return function()
    local identity = eu.parse_identity(api.nvim_get_current_line())
    if not identity then return end

    local entry = self.file_tree:node_entry(identity)
    if not entry:isdir() then
      if util.is_valid_winid(self.win.old_winid) then
        api.nvim_set_current_win(self.win.old_winid)
        if self.config.values.close_on_select then self.win:hide() end

        api.nvim_set_current_win(self.win.old_winid)
        vim.cmd.split(entry.path)
      end
    end
  end
end

---@param self Explorer
function M.n_goto_parent(self)
  return function()
    local current_dir = self:getcwd()
    if not current_dir then return end

    local parent_dir = fn.fnamemodify(current_dir, ":h")
    if parent_dir == self:getcwd() then return end

    self:chdir(parent_dir)

    api.nvim_exec_autocmds("User", { pattern = "DispatchRefresh" })
  end
end

---@param self Explorer
function M.n_goto_cwd(self)
  return function()
    if self:getcwd() == self.dir then return end

    self:chdir(self.dir)

    api.nvim_exec_autocmds("User", { pattern = "DispatchRefresh" })
  end
end

---@param self Explorer
function M.n_goto_node(self)
  return function()
    local indentity = eu.parse_identity(api.nvim_get_current_line())
    if not indentity then return end

    local entry = self.file_tree:node_entry(indentity)
    if not entry then return end

    if entry:isdir() then
      self:chdir(entry.path)

      api.nvim_exec_autocmds("User", { pattern = "DispatchRefresh" })
    else
      M.n_select(self)()
    end
  end
end

---@param self Explorer
---@param tbl table
---@return table
local function get_tbl(self, tbl)
  local lines = {}
  if not self then return lines end
  if not vim.tbl_isempty(tbl.copy) then
    table.insert(lines, { { str = "COPY", hl = "FylerConfirmYellow" } })
    for _, change in ipairs(tbl.copy) do
      table.insert(lines, {
        { str = "| " },
        { str = fs.relpath(self:getcwd(), change.src), hl = "FylerConfirmGrey" },
        { str = " > " },
        { str = fs.relpath(self:getcwd(), change.dst), hl = "FylerConfirmGrey" },
      })
    end
    table.insert(lines, { { str = "" } })
  end

  if not vim.tbl_isempty(tbl.move) then
    table.insert(lines, { { str = "MOVE", hl = "FylerConfirmYellow" } })
    for _, change in ipairs(tbl.move) do
      table.insert(lines, {
        { str = "| " },
        { str = fs.relpath(self:getcwd(), change.src), hl = "FylerConfirmGrey" },
        { str = " > " },
        { str = fs.relpath(self:getcwd(), change.dst), hl = "FylerConfirmGrey" },
      })
    end

    table.insert(lines, { { str = "" } })
  end

  if not vim.tbl_isempty(tbl.create) then
    table.insert(lines, { { str = "CREATE", hl = "FylerConfirmGreen" } })
    for _, change in ipairs(tbl.create) do
      table.insert(lines, {
        { str = "| " },
        { str = fs.relpath(self:getcwd(), change), hl = "FylerConfirmGrey" },
      })
    end

    table.insert(lines, { { str = "" } })
  end

  if not vim.tbl_isempty(tbl.delete) then
    table.insert(lines, { { str = "DELETE", hl = "FylerConfirmRed" } })
    for _, change in ipairs(tbl.delete) do
      table.insert(lines, {
        { str = "| " },
        { str = fs.relpath(self:getcwd(), change), hl = "FylerConfirmGrey" },
      })
    end

    table.insert(lines, { { str = "" } })
  end

  return lines
end

---@param changes table
---@return boolean
local function can_bypass(changes)
  if #changes.copy > 1 then return false end

  if #changes.move > 1 then return false end

  if #changes.create > 5 then return false end

  if not vim.tbl_isempty(changes.delete) then return false end

  return true
end

local function run_mutation(changes)
  for _, change in ipairs(changes.copy) do
    fs.copy(change.src, change.dst)
  end

  for _, change in ipairs(changes.move) do
    fs.move(change.src, change.dst)
  end

  for _, change in ipairs(changes.create) do
    fs.create(change)
  end

  for _, change in ipairs(changes.delete) do
    fs.delete(change)
  end

  vim.schedule(function() api.nvim_exec_autocmds("User", { pattern = "DispatchRefresh" }) end)
end

---@param self Explorer
function M.synchronize(self)
  return a.void_wrap(function()
    local popups = require "fyler.popups"

    local buf_lines = api.nvim_buf_get_lines(self.win.bufnr, 0, -1, false)
    local changes = self.file_tree:diff_with_lines(buf_lines)

    local can_mutate
    if self.config.values.confirm_simple and can_bypass(changes) then
      can_mutate = true
    else
      can_mutate = popups.permission:open(get_tbl(self, changes))
    end

    if can_mutate then run_mutation(changes) end

    api.nvim_exec_autocmds("User", { pattern = "DispatchRefresh" })
  end)
end

---@param self Explorer
function M.dispatch_refresh(self)
  return a.void_wrap(function(arg)
    arg = arg or {}
    arg.data = arg.data or {}

    self.file_tree:update()

    local status_map = self.config.values.git_status and git.status_map() or nil
    local cache_undolevels
    self.win.ui:render {
      ui_lines = ui.Explorer(self.file_tree:totable().children, status_map),

      before = function()
        cache_undolevels = vim.bo[self.win.bufnr].undolevels
        vim.bo[self.win.bufnr].undolevels = -1
      end,

      after = function()
        if arg.data.after then arg.data.after() end
        if not self.win:has_valid_bufnr() then return end

        vim.bo[self.win.bufnr].undolevels = cache_undolevels
        api.nvim_exec_autocmds("User", { pattern = "DrawIndentscope" })
      end,
    }
  end)
end

function M.constrain_cursor(view)
  return function()
    local cur = api.nvim_get_current_line()
    local identity = eu.parse_identity(cur)
    if not identity then return end

    local _, ub = string.find(cur, identity)
    if not view.win:has_valid_winid() then return end

    local row, col = util.unpack(api.nvim_win_get_cursor(view.win.winid))
    if col <= ub then api.nvim_win_set_cursor(view.win.winid, { row, ub + 1 }) end
  end
end

---@param self Explorer
function M.try_focus_buffer(self)
  return function(arg)
    if not fs.is_valid_path(arg.file) then return end
    if not util.is_valid_winid(self.win.winid) then return end

    if string.match(arg.file, "^fyler://*") then
      if not self.win.old_bufnr then return end
      if not util.is_valid_bufnr(self.win.old_bufnr) then return end

      local old_bufname = fn.bufname(self.win.old_bufnr)
      if old_bufname == "" or string.match(old_bufname, "^fyler://*") then return end

      arg.file = fs.abspath(old_bufname)
    end

    local current_dir = self:getcwd()
    if not current_dir then return end
    if not vim.startswith(arg.file, current_dir) then self:chdir(fn.fnamemodify(arg.file, ":h")) end

    local indentity = self.file_tree:focus_path(arg.file)
    if not indentity then return end

    vim.schedule(function()
      api.nvim_exec_autocmds("User", {
        pattern = "DispatchRefresh",
        data = {
          after = function()
            if not self.win:has_valid_winid() then return end

            local buf_lines = api.nvim_buf_get_lines(self.win.bufnr, 0, -1, false)
            for ln, buf_line in ipairs(buf_lines) do
              if buf_line:find(indentity) then api.nvim_win_set_cursor(self.win.winid, { ln, 0 }) end
            end
          end,
        },
      })
    end)
  end
end

local extmark_namespace = api.nvim_create_namespace "Fyler-indent-scope"

---@param self Explorer
function M.draw_indentscope(self)
  local function draw_line(ln)
    if not self.win:has_valid_bufnr() then return end

    local cur_line = util.unpack(api.nvim_buf_get_lines(self.win.bufnr, ln - 1, ln, false))
    local cur_indent = eu.parse_indentation(cur_line)
    if cur_indent == 0 then return end

    local indent_depth = math.floor(cur_indent * 0.5)
    for i = 1, indent_depth do
      api.nvim_buf_set_extmark(self.win.bufnr, extmark_namespace, ln - 1, 0, {
        hl_mode = "combine",
        virt_text = {
          {
            self.config.values.indentscope.marker,
            self.config.values.indentscope.group,
          },
        },
        virt_text_pos = "overlay",
        virt_text_win_col = (i - 1) * 2,
      })
    end
  end

  return function()
    if not self.win:has_valid_bufnr() then return end
    if not self.config.values.indentscope.enabled then return end

    api.nvim_buf_clear_namespace(self.win.bufnr, extmark_namespace, 0, -1)
    for i = 1, api.nvim_buf_line_count(self.win.bufnr) do
      draw_line(i)
    end
  end
end

return M

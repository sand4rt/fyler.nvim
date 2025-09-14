local a = require "fyler.lib.async"
local eu = require "fyler.explorer.util"
local fs = require "fyler.lib.fs"
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
    local indentity = eu.parse_ref_id(api.nvim_get_current_line())
    if not indentity then return end

    local entry = self.file_tree:node_entry(indentity)
    if not entry then return end

    if entry:isdir() then
      if entry.open then
        self.file_tree:collapse_node(indentity)
      else
        self.file_tree:expand_node(indentity)
      end

      api.nvim_exec_autocmds("User", { pattern = "DispatchRefresh" })
    else
      if util.is_valid_winid(self.win.old_winid) then
        if self.config.values.close_on_select then self.win:hide() end

        api.nvim_set_current_win(self.win.old_winid)
        api.nvim_win_call(self.win.old_winid, function() vim.cmd.edit(vim.fn.fnameescape(entry.path)) end)
      end
    end
  end
end

---@param self Explorer
function M.n_select_tab(self)
  return function()
    local ref_id = eu.parse_ref_id(api.nvim_get_current_line())
    if not ref_id then return end

    local entry = self.file_tree:node_entry(ref_id)
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
    local ref_id = eu.parse_ref_id(api.nvim_get_current_line())
    if not ref_id then return end

    local entry = self.file_tree:node_entry(ref_id)
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
    local ref_id = eu.parse_ref_id(api.nvim_get_current_line())
    if not ref_id then return end

    local entry = self.file_tree:node_entry(ref_id)
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
function M.n_collapse_all(self)
  return function()
    self.file_tree:collapse_all()

    api.nvim_exec_autocmds("User", { pattern = "DispatchRefresh" })
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
    local indentity = eu.parse_ref_id(api.nvim_get_current_line())
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
function M.n_collapse_node(self)
  return function()
    local ref_id = eu.parse_ref_id(api.nvim_get_current_line())
    if not ref_id then return end

    local entry = self.file_tree:node_entry(ref_id)
    if not entry then return end

    -- should not collapse root, so get it's id
    local root_id = self.file_tree.tree.root and self.file_tree.tree.root.value
    if entry:isdir() and ref_id == root_id then return end

    local collapse_target = self.file_tree:find_parent(ref_id)
    if not collapse_target then return end
    if collapse_target == root_id and not entry.open then return end
    local focus_ref_id

    if entry:isdir() and entry.open then
      self.file_tree:collapse_node(ref_id)
      focus_ref_id = ref_id
    else
      self.file_tree:collapse_node(collapse_target)
      focus_ref_id = collapse_target
    end

    api.nvim_exec_autocmds("User", {
      pattern = "DispatchRefresh",
      data = {
        after = function()
          if not self.win:has_valid_winid() then return end
          local marker = string.format("/%05d", focus_ref_id)
          local lines = api.nvim_buf_get_lines(self.win.bufnr, 0, -1, false)
          for ln, line in ipairs(lines) do
            if line:find(marker, 1, true) then
              api.nvim_win_set_cursor(self.win.winid, { ln, 0 })
              break
            end
          end
        end,
      },
    })
  end
end

local function get_parent_dir(path) return vim.fn.fnamemodify(path, ":h") end

local function is_directory(path) return vim.fn.isdirectory(path) == 1 end

local function sort_by_depth(paths, reverse)
  table.sort(paths, function(a, b)
    local depth_a = select(2, string.gsub(a, "/", ""))
    local depth_b = select(2, string.gsub(b, "/", ""))
    if reverse then
      return depth_a > depth_b
    else
      return depth_a < depth_b
    end
  end)
  return paths
end

local function get_ordered_operations(changes)
  local operations = {}
  local deleted_paths = {}

  for _, change in ipairs(changes.delete) do
    deleted_paths[change] = true
  end

  for _, change in ipairs(changes.move) do
    deleted_paths[change.src] = true
  end

  local files_to_delete = {}
  for _, change in ipairs(changes.delete) do
    if not is_directory(change) then table.insert(files_to_delete, change) end
  end
  sort_by_depth(files_to_delete, true)

  for _, change in ipairs(files_to_delete) do
    table.insert(operations, { type = "delete", path = change })
  end

  local dirs_to_create = {}
  local processed_dirs = {}

  local all_destinations = {}

  for _, change in ipairs(changes.create) do
    if is_directory(change) then
      table.insert(all_destinations, change)
    else
      table.insert(all_destinations, get_parent_dir(change))
    end
  end

  for _, change in ipairs(changes.move) do
    table.insert(all_destinations, get_parent_dir(change.dst))
  end

  for _, change in ipairs(changes.copy) do
    table.insert(all_destinations, get_parent_dir(change.dst))
  end

  for _, dest in ipairs(all_destinations) do
    local current = dest
    while current and current ~= "." and current ~= "/" and not processed_dirs[current] do
      if not vim.fn.isdirectory(current) == 1 and not deleted_paths[current] then
        table.insert(dirs_to_create, current)
        processed_dirs[current] = true
      end
      current = get_parent_dir(current)
    end
  end

  sort_by_depth(dirs_to_create, false)

  for _, dir in ipairs(dirs_to_create) do
    table.insert(operations, { type = "create", path = dir })
  end

  for _, change in ipairs(changes.create) do
    if not processed_dirs[change] then table.insert(operations, { type = "create", path = change }) end
  end

  for _, change in ipairs(changes.move) do
    table.insert(operations, { type = "move", src = change.src, dst = change.dst })
  end

  for _, change in ipairs(changes.copy) do
    table.insert(operations, { type = "copy", src = change.src, dst = change.dst })
  end

  local dirs_to_delete = {}
  for _, change in ipairs(changes.delete) do
    if is_directory(change) then table.insert(dirs_to_delete, change) end
  end
  sort_by_depth(dirs_to_delete, true)

  for _, change in ipairs(dirs_to_delete) do
    table.insert(operations, { type = "delete", path = change })
  end

  return operations
end

---@param self Explorer
---@param tbl table
---@return table
local function get_tbl(self, tbl)
  local lines = {}
  if not self then return lines end

  local ordered_operations = get_ordered_operations(tbl)

  local grouped_ops = {}
  local seen_types = {}

  for _, op in ipairs(ordered_operations) do
    if not grouped_ops[op.type] then
      grouped_ops[op.type] = {}
      table.insert(seen_types, op.type)
    end
    table.insert(grouped_ops[op.type], op)
  end

  for _, op_type in ipairs(seen_types) do
    local ops = grouped_ops[op_type]

    if op_type == "delete" then
      table.insert(lines, { { str = "DELETE", hlg = "FylerConfirmRed" } })
      for _, op in ipairs(ops) do
        table.insert(lines, {
          { str = "| " },
          { str = fs.relpath(self:getcwd(), op.path), hlg = "FylerConfirmGrey" },
        })
      end
      table.insert(lines, { { str = "" } })
    elseif op_type == "create" then
      table.insert(lines, { { str = "CREATE", hlg = "FylerConfirmGreen" } })
      for _, op in ipairs(ops) do
        table.insert(lines, {
          { str = "| " },
          { str = fs.relpath(self:getcwd(), op.path), hlg = "FylerConfirmGrey" },
        })
      end
      table.insert(lines, { { str = "" } })
    elseif op_type == "move" then
      table.insert(lines, { { str = "MOVE", hlg = "FylerConfirmYellow" } })
      for _, op in ipairs(ops) do
        table.insert(lines, {
          { str = "| " },
          { str = fs.relpath(self:getcwd(), op.src), hlg = "FylerConfirmGrey" },
          { str = " > " },
          { str = fs.relpath(self:getcwd(), op.dst), hlg = "FylerConfirmGrey" },
        })
      end
      table.insert(lines, { { str = "" } })
    elseif op_type == "copy" then
      table.insert(lines, { { str = "COPY", hlg = "FylerConfirmYellow" } })
      for _, op in ipairs(ops) do
        table.insert(lines, {
          { str = "| " },
          { str = fs.relpath(self:getcwd(), op.src), hlg = "FylerConfirmGrey" },
          { str = " > " },
          { str = fs.relpath(self:getcwd(), op.dst), hlg = "FylerConfirmGrey" },
        })
      end
      table.insert(lines, { { str = "" } })
    end
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
  local ordered_operations = get_ordered_operations(changes)

  for _, op in ipairs(ordered_operations) do
    if op.type == "copy" then
      fs.copy(op.src, op.dst)
    elseif op.type == "move" then
      fs.move(op.src, op.dst)
    elseif op.type == "create" then
      fs.create(op.path)
    elseif op.type == "delete" then
      fs.delete(op.path)
    end
  end

  vim.schedule(function() api.nvim_exec_autocmds("User", { pattern = "DispatchRefresh" }) end)
end

local function has_changes(changes) return #changes.create + #changes.delete + #changes.move + #changes.copy > 0 end

---@param self Explorer
function M.synchronize(self)
  return a.void_wrap(function()
    local popups = require "fyler.popups"

    local buf_lines = api.nvim_buf_get_lines(self.win.bufnr, 0, -1, false)
    local changes = self.file_tree:diff_with_lines(buf_lines)

    local can_mutate
    if not has_changes(changes) or self.config.values.confirm_simple and can_bypass(changes) then
      can_mutate = true
    else
      can_mutate = popups.permission.create(get_tbl(self, changes))
    end

    if can_mutate then run_mutation(changes) end
  end)
end

---@param self Explorer
function M.dispatch_refresh(self)
  return a.void_wrap(function(arg)
    arg = arg or {}
    arg.data = arg.data or {}

    self.file_tree:update()

    local cache_undolevels
    self.win.ui:render {
      ui_lines = ui(self.file_tree:totable()),

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
    local ref_id = eu.parse_ref_id(cur)
    if not ref_id then return end

    local _, ub = string.find(cur, ref_id)
    if not view.win:has_valid_winid() then return end

    local row, col = util.unpack(api.nvim_win_get_cursor(view.win.winid))
    if col <= ub then api.nvim_win_set_cursor(view.win.winid, { row, ub + 1 }) end
  end
end

---@param self Explorer
function M.track_buffer(self)
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
    local cur_indent = eu.parse_indent_level(cur_line)
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

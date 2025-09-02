local Tree = require "fyler.explorer.file_tree"
local Win = require "fyler.lib.win"

---@class Explorer
---@field dir string
---@field win Win
---@field file_tree FileTree
---@field config table
local M = {}
M.__index = M

---@type table<string, Explorer>
local instances = {}
---@type string|nil
local recentdir

---@param dir string
---@param instance Explorer
function M.register(dir, instance)
  assert(dir, "cannot register without directory")

  instances[dir] = instance
end

---@param dir string|nil
---@return Explorer|nil
function M.instance(dir) return instances[dir] end

---@return Explorer|nil
function M.current() return M.instance(recentdir) end

---@param dir string
---@param config table
---@return Explorer
function M.new(dir, config)
  local instance = {
    dir = dir,
    config = config,
  }

  setmetatable(instance, M)
  M.register(dir, instance)

  return instance
end

---@return string|nil
function M:getcwd()
  if self.file_tree then
    return self.file_tree:node_entry(self.file_tree.tree.root.value).path
  else
    return nil
  end
end

---@param dir string
function M:chdir(dir)
  assert(dir, "cannot change directory with empty path")

  self.file_tree = Tree.new(vim.fn.fnamemodify(dir, ":t"), true, dir, "directory")
end

---@return boolean
function M:is_visible() return self.win and self.win:is_visible() end

function M:focus()
  if self.win then self.win:focus() end
end

---@param dir string
---@param kind WinKind
function M:open(dir, kind)
  local reversed_maps = self.config.get_reversed_maps()

  if self:getcwd() == dir then
    if self:is_visible() then
      self:focus()
      return
    end
  else
    self:chdir(dir)
  end

  recentdir = dir

  -- print(vim.inspect(self.config.values.win.win_opts), vim.inspect(self.config.values.win.buf_opts))

  -- stylua: ignore start
  self.win = Win.new {
    autocmds      = {
      ["BufReadCmd"]   = self:_action "dispatch_refresh",
      ["BufWriteCmd"]  = self:_action "synchronize",
      ["CursorMoved"]  = self:_action "constrain_cursor",
      ["CursorMovedI"] = self:_action "constrain_cursor",
      ["TextChanged"]  = self:_action "draw_indentscope",
      ["TextChangedI"] = self:_action "draw_indentscope",
      ["WinClosed"]    = self:_action "n_close",
    },
    border        = self.config.values.win.border,
    bufname       = string.format("fyler://%s", dir),
    bottom        = self.config.values.win.bottom,
    buf_opts      = self.config.values.win.buf_opts,
    enter         = true,
    footer        = self.config.values.win.footer,
    footer_pos    = self.config.values.win.footer,
    height        = self.config.values.win.height,
    kind          = kind,
    left          = self.config.values.win.left,
    mappings      = {
      [reversed_maps["CloseView"]]    = self:_action "n_close",
      [reversed_maps["Select"]]       = self:_action "n_select",
      [reversed_maps["SelectTab"]]    = self:_action "n_select_tab",
      [reversed_maps["SelectSplit"]]  = self:_action "n_select_split",
      [reversed_maps["SelectVSplit"]] = self:_action "n_select_v_split",
      [reversed_maps["GotoParent"]]   = self:_action "n_goto_parent",
      [reversed_maps["GotoCwd"]]      = self:_action "n_goto_cwd",
      [reversed_maps["GotoNode"]]     = self:_action "n_goto_node",
    },
    render        = self:_action "dispatch_refresh",
    right         = self.config.values.win.right,
    title         = self.config.values.win.title,
    title_pos     = self.config.values.win.title,
    top           = self.config.values.win.top,
    user_autocmds = {
      ["DispatchRefresh"] = self:_action "dispatch_refresh"
    },
    width         = self.config.values.win.width,
    win_opts      = self.config.values.win.win_opts,
  }
  -- stylua: ignore end

  self.win:show()
end

---@param name string
function M:_action(name)
  local action = require("fyler.explorer.actions")[name]
  assert(action, string.format("action %s is not available", name))

  return action(self)
end

return M

local M = {}

local api = vim.api

---@param winid? number
---@return boolean
function M.is_valid_winid(winid) return type(winid) == "number" and api.nvim_win_is_valid(winid) end

---@param bufnr? number
---@return boolean
function M.is_valid_bufnr(bufnr) return type(bufnr) == "number" and api.nvim_buf_is_valid(bufnr) end

---@param win FylerWin
---@return boolean
function M.has_valid_winid(win) return type(win.winid) == "number" and api.nvim_win_is_valid(win.winid) end

---@param win FylerWin
---@return boolean
function M.has_valid_bufnr(win) return type(win.bufnr) == "number" and api.nvim_buf_is_valid(win.bufnr) end

---@param str string
---@return string
function M.match_id(str) return str:match(" /(%d%d%d%d%d)") end

---@param str string
---@return string
function M.match_indent(str) return str:match("^(%s*)") end

---@param str string
---@return string
function M.match_name(str)
  if M.match_id(str) then
    return str:match("/%d%d%d%d%d (.*)$")
  else
    return str:gsub("^%s*", ""):match(".*")
  end
end

---@param str string
---@return string, string, string
function M.match_contents(str) return M.match_id(str), M.match_name(str), M.match_indent(str) end

---@param lines string[]
function M.filter_blank_lines(lines)
  return vim.iter(lines):filter(function(line) return line ~= "" end):totable()
end

---@param a table
---@param b table
---@return table
function M.tbl_merge(a, b) return vim.tbl_deep_extend("force", a, b) end

---@param tbl table
---@return table
function M.unique(tbl)
  local res = {}
  for i = 1, #tbl do
    if tbl[i] and not vim.tbl_contains(res, tbl[i]) then table.insert(res, tbl[i]) end
  end

  return res
end

return M

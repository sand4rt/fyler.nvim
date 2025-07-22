local List = require("fyler.lib.structs.list")
local Stack = require("fyler.lib.structs.stack")

local a = require("fyler.lib.async")

local M = {}

local uv = vim.uv or vim.loop
local fn = vim.fn

---@return string
function M.getcwd()
  return uv.cwd() or fn.getcwd(0)
end

---@param path string
---@return string
function M.normalize(path)
  return vim.fs.normalize(path)
end

---@return string
function M.joinpath(...)
  return vim.fs.joinpath(...)
end

---@param path string
---@return string
function M.abspath(path)
  return vim.fs.abspath(path)
end

---@param path string
function M.relpath(base, path)
  return vim.fs.relpath(base, path)
end

---@param path string
---@return string?, string?
function M.resolve_link(path)
  local res_path = nil
  local res_type = nil
  while true do
    local stat = uv.fs_stat(path)
    if not stat then
      break
    end

    local linkdata = uv.fs_readlink(path)
    if not linkdata then
      res_path = path
      res_type = stat.type
      break
    end

    path = linkdata
  end

  return res_path, res_type
end

---@param path string
---@param cb fun(err?: string, items: table)
M.ls = a.async(function(path, cb)
  local stat_err, stat = a.await(uv.fs_stat, path)
  if not stat then
    return cb(stat_err, {})
  end

  ---@diagnostic disable-next-line: param-type-mismatch
  local dir = uv.fs_opendir(path, nil, 1000)
  local items = {}

  while true do
    local _, entries = a.await(uv.fs_readdir, dir)
    if not entries then
      break
    end

    items = vim.list_extend(
      items,
      vim
        .iter(entries)
        :map(function(entry)
          local link_path, link_type = M.resolve_link(M.joinpath(path, entry.name))
          return {
            name = entry.name,
            type = entry.type,
            path = M.joinpath(path, entry.name),
            link_path = link_path,
            link_type = link_type,
          }
        end)
        :totable()
    )
  end

  return cb(nil, items)
end)

---@param path string
---@param cb fun(err?: string, success: boolean)
M.touch = a.async(function(path, cb)
  local stat_err, stat = a.await(uv.fs_stat, path)
  if stat then
    return cb(stat_err, false)
  end

  local fd_err, fd = a.await(uv.fs_open, path, "a", 420)
  if not fd then
    return cb(fd_err, false)
  end

  return cb(a.await(uv.fs_close, fd))
end)

---@param path string
---@param cb fun(err?: string, success: boolean)
M.rm = a.async(function(path, cb)
  local stat_err, stat = a.await(uv.fs_stat, path)
  if not stat or stat.type == "directory" then
    return cb(stat_err, false)
  end

  local unlink_err, success = a.await(uv.fs_unlink, path)
  if not success then
    return cb(unlink_err, false)
  end

  return cb(nil, true)
end)

---@param path string
---@param cb fun(err?: string, success: boolean)
M.rm_r = a.async(function(path, cb)
  local stat_err, stat = a.await(uv.fs_stat, path)
  if not stat then
    return cb(stat_err, false)
  end

  local stk, lst = Stack(), List()

  stk:push { path = path, type = stat.type }

  while not stk:is_empty() do
    local cur_entry = stk:pop()

    lst:insert(1, cur_entry)

    if cur_entry.type == "directory" then
      local ls_err, entries = a.await(M.ls, cur_entry.path)
      if ls_err then
        return cb(ls_err, false)
      end

      for _, entry in ipairs(entries) do
        stk:push(entry)
      end
    end
  end

  for _, entry in ipairs(lst:totable()) do
    if entry.type == "directory" then
      local rmdir_err, rmdir_success = a.await(M.rmdir, entry.path)
      if not rmdir_success then
        return cb(rmdir_err, false)
      end
    else
      local rm_err, rm_success = a.await(M.rm, entry.path)
      if not rm_success then
        return cb(rm_err, false)
      end
    end
  end

  return cb(nil, true)
end)

---@param path string
---@param cb fun(err?: string, success: boolean)
M.mkdir = a.async(function(path, cb)
  local stat_err, stat = a.await(uv.fs_stat, path)
  if stat and stat.type == "directory" then
    return cb(stat_err, false)
  end

  local mkdir_err, success = a.await(uv.fs_mkdir, path, 493)
  if not success then
    return cb(mkdir_err, false)
  end

  return cb(nil, true)
end)

---@param path string
---@param cb fun(err?: string, success: boolean)
M.mkdir_p = a.async(function(path, cb)
  local parts = vim
    .iter(vim.split(path, "/"))
    :filter(function(part)
      return part ~= ""
    end)
    :totable()

  local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

  local dir = is_win and parts[1] or ""

  local start_idx = is_win and 2 or 1
  for i = start_idx, #parts do
    dir = dir .. string.format("/%s", parts[i])

    local _, stat = a.await(uv.fs_stat, dir)
    if not stat then
      local mkdir_err, mkdir_success = a.await(M.mkdir, dir)
      if not mkdir_success then
        return cb(mkdir_err, false)
      end
    end
  end

  return cb(nil, true)
end)

---@param path string
---@param cb fun(err?: string, success: boolean)
M.rmdir = a.async(function(path, cb)
  local stat_err, stat = a.await(uv.fs_stat, path)
  if not stat then
    return cb(stat_err, false)
  end

  local rmdir_err, success = a.await(uv.fs_rmdir, path)
  if not success then
    return cb(rmdir_err, false)
  end

  return cb(nil, true)
end)

---@param src_path string
---@param dst_path string
---@param cb fun(err?: string, success: boolean)
M.mv = a.async(function(src_path, dst_path, cb)
  local stat_err, src_stat = a.await(uv.fs_stat, src_path)
  if not src_stat then
    return cb(stat_err, false)
  end

  local _, dst_stat = a.await(uv.fs_stat, dst_path)
  if dst_stat then
    return cb("Destination path already exists", false)
  end

  local rename_err, rename_success = a.await(uv.fs_rename, src_path, dst_path)
  if not rename_success then
    return cb(rename_err, false)
  end

  return cb(nil, true)
end)

---@param path string
---@param cb fun(err?: string, success: boolean)
M.create = a.async(function(path, cb)
  local mkdirp_err, mkdirp_success =
    a.await(M.mkdir_p, fn.fnamemodify(path, vim.endswith(path, "/") and ":h:h" or ":h"))
  if not mkdirp_success then
    return cb(mkdirp_err, false)
  end

  if vim.endswith(path, "/") then
    local mkdir_err, mkdir_success = a.await(M.mkdir, path)
    if not mkdir_success then
      return cb(mkdir_err, false)
    end
  else
    local touch_err, touch_success = a.await(M.touch, path)
    if not touch_success then
      return cb(touch_err, false)
    end
  end

  return cb(nil, true)
end)

local function get_alt_buf(for_buf)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and buf ~= for_buf then
      return buf
    end
  end

  return vim.api.nvim_create_buf(false, true)
end

---@param path string
---@param cb fun(err?: string, success: boolean)
M.delete = a.async(function(path, cb)
  local rm_r_err, rm_r_success = a.await(M.rm_r, path)
  if not rm_r_success then
    return cb(rm_r_err, false)
  end

  local buf = fn.bufnr(path)
  if buf == -1 then
    return cb("Unable to find buffer to delete", false)
  end

  local alt = get_alt_buf(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      if alt < 1 or alt == buf then
        alt = vim.api.nvim_create_buf(true, false)
      end

      vim.api.nvim_win_set_buf(win, alt)
    end
  end

  local success, msg = pcall(vim.api.nvim_buf_delete, buf, { force = true })
  if not success then
    return cb(msg, false)
  end

  return cb(nil, true)
end)

---@param src_path string
---@param dst_path string
---@param cb fun(err?: string, success: boolean)
M.move = a.async(function(src_path, dst_path, cb)
  local mkdirp_err, mkdirp_success = a.await(M.mkdir_p, fn.fnamemodify(dst_path, ":h"))
  if not mkdirp_success then
    return cb(mkdirp_err, false)
  end

  local mv_err, mv_success = a.await(M.mv, src_path, dst_path)
  if not mv_success then
    return cb(mv_err, false)
  end

  local src_buf = fn.bufnr(src_path)
  if src_buf == -1 then
    return cb("unable to find moved buffer", false)
  end

  local dst_buf = fn.bufadd(dst_path)
  fn.bufload(dst_buf)
  vim.bo[dst_buf].buflisted = true

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == src_buf then
      vim.api.nvim_win_set_buf(win, dst_buf)
    end
  end

  local success, msg = pcall(vim.api.nvim_buf_delete, src_buf, { force = true })
  if not success then
    return cb(msg, false)
  end

  return cb(nil, true)
end)

return M

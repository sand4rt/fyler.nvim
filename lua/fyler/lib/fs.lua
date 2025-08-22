local List = require("fyler.lib.structs.list")
local Stack = require("fyler.lib.structs.stack")
local a = require("fyler.lib.async")
local hooks = require("fyler.hooks")
local util = require("fyler.lib.util")

local M = {}

local fn = vim.fn
local uv = vim.uv or vim.loop

---@return string
function M.getcwd() return uv.cwd() or fn.getcwd(0) end

---@param path string
---@return string
function M.normalize(path) return vim.fs.normalize(path) end

---@return string
function M.joinpath(...) return vim.fs.joinpath(...) end

---@param path string
---@return string
function M.abspath(path) return vim.fs.abspath(path) end

---@param path string
function M.relpath(base, path) return vim.fs.relpath(base, path) end

---@param path string
---@return boolean
function M.is_valid_path(path)
  local prefixless_path = string.gsub(path, "^fyler://", "")
  local _, err = uv.fs_stat(prefixless_path)
  return err == nil
end

do
  local fs_map = {
    resolve_link = function(path, cb)
      local res_path = nil
      local res_type = nil
      local stat = select(2, a.uv.fs_stat(path))

      while stat do
        local linkdata = select(2, a.uv.fs_readlink(path))
        if not linkdata then
          res_path = path
          res_type = stat.type
          break
        end

        path, stat = linkdata, select(2, a.uv.fs_stat(path))
      end

      return cb(res_path, res_type)
    end,

    ls = function(path, cb)
      local err, stat = a.uv.fs_stat(path)
      assert(stat, err)
      assert(stat.type == "directory", "Path must be a directory")

      local dir = select(2, a.uv.fs_opendir(path, 1000))
      local items = {}
      while true do
        local entries = select(2, a.uv.fs_readdir(dir))
        if not entries then break end

        items = vim.list_extend(
          items,
          util.tbl_map(entries, function(entry)
            local lpath, ltype = M.resolve_link(M.joinpath(path, entry.name))
            return {
              name = entry.name,
              type = entry.type,
              path = M.joinpath(path, entry.name),
              lpath = lpath,
              ltype = ltype,
            }
          end)
        )
      end

      return cb(nil, items)
    end,

    touch = function(path, cb)
      local stat_err = a.uv.fs_stat(path)
      assert(stat_err, stat_err)

      local fd_err, fd = a.uv.fs_open(path, "a", 420)
      assert(fd, fd_err)

      return cb(a.uv.fs_close(fd))
    end,

    rm = function(path, cb)
      local stat_err, stat = a.uv.fs_stat(path)
      assert(stat, stat_err)
      assert(stat.type ~= "directory", "Path must not be a directory")

      local unlink_err, success = a.uv.fs_unlink(path)
      assert(success, unlink_err)

      return cb(nil, true)
    end,

    rm_r = function(path, cb)
      local stat_err, stat = a.uv.fs_stat(path)
      assert(stat, stat_err)

      local stack, list = Stack.new(), List.new()
      stack:push { path = path, type = stat.type }

      while not stack:is_empty() do
        local cur_entry = stack:pop()
        list:insert(1, cur_entry)

        if cur_entry.type == "directory" then
          local ls_err, entries = M.ls(cur_entry.path)
          if ls_err then return cb(ls_err, false) end

          for _, entry in ipairs(entries) do
            stack:push(entry)
          end
        end
      end

      for _, entry in ipairs(list:totable()) do
        if entry.type == "directory" then
          local rmdir_err, rmdir_success = M.rmdir(entry.path)
          assert(rmdir_success, rmdir_err)
        else
          local rm_err, rm_success = M.rm(entry.path)
          assert(rm_success, rm_err)
        end
      end

      return cb(nil, true)
    end,

    mkdir = function(path, cb)
      local stat = select(2, a.uv.fs_stat(path))
      assert((not stat or stat.type ~= "directory"), "Path already exists")

      local mkdir_err, success = a.uv.fs_mkdir(path, 493)
      assert(success, mkdir_err)

      return cb(nil, true)
    end,

    mkdir_p = function(path, cb)
      local parts = util.filter_bl(vim.split(path, "/"))
      local is_win = fn.has("win32") == 1 or fn.has("win64") == 1
      local dir = is_win and parts[1] or ""

      local start_idx = is_win and 2 or 1
      for i = start_idx, #parts do
        dir = dir .. string.format("/%s", parts[i])

        local stat = select(2, a.uv.fs_stat(dir))
        if not stat then
          local mkdir_err, mkdir_success = M.mkdir(dir)
          assert(mkdir_success, mkdir_err)
        end
      end

      return cb(nil, true)
    end,

    rmdir = function(path, cb)
      local stat_err, stat = a.uv.fs_stat(path)
      assert(stat, stat_err)

      local rmdir_err, success = a.uv.fs_rmdir(path)
      assert(success, rmdir_err)

      return cb(nil, true)
    end,

    mv = function(src_path, dst_path, cb)
      local stat_err, src_stat = a.uv.fs_stat(src_path)
      assert(src_stat, stat_err)

      local stat_err = a.uv.fs_stat(dst_path)
      assert(stat_err, "Destination path already exists")

      local rename_err, rename_success = a.uv.fs_rename(src_path, dst_path)
      assert(rename_success, rename_err)

      return cb(nil, true)
    end,

    cp = function(src_path, dst_path, cb)
      local stat_err, src_stat = a.uv.fs_stat(src_path)
      assert(src_stat, stat_err)
      assert(src_stat.type ~= "directory", "Source path must not be a directory")

      local stat_err = a.uv.fs_stat(dst_path)
      assert(stat_err, "Destination path already exists")

      local copyfile_err, copyfile_success = a.uv.fs_copyfile(src_path, dst_path, nil)
      assert(copyfile_success, copyfile_err)

      return cb(nil, true)
    end,

    cp_r = function(src_path, dst_path, cb)
      local stat_err, src_stat = a.uv.fs_stat(src_path)
      assert(src_stat, stat_err)

      local stat_err = a.uv.fs_stat(dst_path)
      assert(stat_err, "Destination path already exists")

      local stk = Stack.new()
      stk:push {
        dst_path = dst_path,
        src_path = src_path,
        type = src_stat.type,
      }

      while not stk:is_empty() do
        local cur_entry = stk:pop()

        if cur_entry.type == "directory" then
          local mkdir_err, mkdir_success = M.mkdir_p(cur_entry.dst_path)
          assert(mkdir_success, mkdir_err)

          local ls_err, entries = M.ls(cur_entry.src_path)
          if ls_err then return cb(ls_err, false) end
          assert(not ls_err, ls_err)

          for _, entry in ipairs(entries) do
            local dst_entry_path = M.joinpath(cur_entry.dst_path, entry.name)
            stk:push {
              src_path = entry.path,
              dst_path = dst_entry_path,
              type = entry.type,
            }
          end
        else
          local copyfile_err, copyfile_success = a.uv.fs_copyfile(cur_entry.src_path, cur_entry.dst_path, nil)
          assert(copyfile_success, copyfile_err)
        end
      end

      return cb(nil, true)
    end,

    create = function(path, cb)
      local mkdirp_err, mkdirp_success = M.mkdir_p(fn.fnamemodify(path, vim.endswith(path, "/") and ":h:h" or ":h"))
      assert(mkdirp_success, mkdirp_err)

      if vim.endswith(path, "/") then
        local mkdir_err, mkdir_success = M.mkdir(path)
        assert(mkdir_success, mkdir_err)
      else
        local touch_err, touch_success = M.touch(path)
        assert(touch_success, touch_err)
      end

      return cb(nil, true)
    end,

    delete = function(path, cb)
      local rm_r_err, rm_r_success = M.rm_r(path)
      assert(rm_r_success, rm_r_err)

      vim.schedule_wrap(hooks.on_delete)(path)

      return cb(nil, true)
    end,

    move = function(src_path, dst_path, cb)
      local mkdirp_err, mkdirp_success = M.mkdir_p(fn.fnamemodify(dst_path, ":h"))
      assert(mkdirp_success, mkdirp_err)

      local mv_err, mv_success = M.mv(src_path, dst_path)
      assert(mv_success, mv_err)

      vim.schedule_wrap(hooks.on_rename)(src_path, dst_path)

      return cb(nil, true)
    end,

    copy = function(src_path, dst_path, cb)
      local stat_err, src_stat = a.uv.fs_stat(src_path)
      assert(src_stat, stat_err)

      local stat_err = a.uv.fs_stat(dst_path)
      assert(stat_err, "Destination path already exists")

      local mkdirp_err, mkdirp_success = M.mkdir_p(fn.fnamemodify(dst_path, ":h"))
      assert(mkdirp_success, mkdirp_err)

      if src_stat.type == "directory" then
        local cp_r_err, cp_r_success = M.cp_r(src_path, dst_path)
        assert(cp_r_success, cp_r_err)
      else
        local copyfile_err, copyfile_success = a.uv.fs_copyfile(src_path, dst_path, nil)
        assert(copyfile_success, copyfile_err)
      end

      return cb(nil, true)
    end,
  }

  for name, fn in pairs(fs_map) do
    M[name] = a.wrap(fn)
  end
end

return M

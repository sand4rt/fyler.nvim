local List = require "fyler.lib.structs.list"
local Stack = require "fyler.lib.structs.stack"
local hooks = require "fyler.hooks"
local M = {}
local uv = vim.uv or vim.loop

function M.cwd() return uv.cwd() or vim.fn.getcwd(0) end

function M.normalize(path) return vim.fs.normalize(path) end

function M.joinpath(...) return vim.fs.joinpath(...) end

function M.abspath(path) return vim.fs.abspath(path) end

function M.relpath(base, path) return vim.fs.relpath(base, path) end

local function stat_exists(path) return not not uv.fs_stat(path) end

function M.exists(path) return stat_exists(path) end

function M.is_valid_path(path)
  local clean_path = path:gsub("^fyler://", "")
  return stat_exists(clean_path)
end

function M.resolve_link(link)
  local current_path = link
  local stat = uv.fs_stat(current_path)

  while stat do
    local target = uv.fs_readlink(current_path)
    if not target then return current_path, stat.type end

    current_path = target
    stat = uv.fs_stat(current_path)
  end

  return nil, nil
end

function M.list_dir(path)
  local stat = uv.fs_stat(path)
  if not (stat and stat.type == "directory") then return {} end

  ---@diagnostic disable-next-line: param-type-mismatch
  local dir, open_err = uv.fs_opendir(path, nil, 1000)
  assert(dir, open_err or ("Unable to open directory: " .. path))

  local items = {}
  repeat
    local entries = uv.fs_readdir(dir)
    if entries then
      for _, entry in ipairs(entries) do
        local full_path = M.joinpath(path, entry.name)
        local resolved_path, resolved_type = M.resolve_link(full_path)
        local item = {
          name = entry.name,
          path = resolved_path or full_path,
          type = entry.type or resolved_type,
        }

        if entry.type == "link" then item.link = full_path end

        if item.type == "directory" then item.open = false end

        table.insert(items, item)
      end
    end
  until not entries

  uv.fs_closedir(dir)

  return items
end

function M.create_file(path)
  if stat_exists(path) then return end

  local fd, err = uv.fs_open(path, "a", 420)
  assert(fd, err or ("Failed to create file: " .. path))
  uv.fs_close(fd)
end

function M.remove_file(path)
  local stat = uv.fs_stat(path)
  assert(stat and stat.type ~= "directory", "Cannot remove directory with remove_file: " .. path)

  local success, unlink_err = uv.fs_unlink(path)
  assert(success, unlink_err or ("Failed to remove file: " .. path))
end

function M.remove_recursive(path)
  local stat = uv.fs_stat(path)
  if not stat then return end

  local to_process = Stack.new()
  local to_delete = List.new()
  to_process:push { path = path, type = stat.type }

  while not to_process:is_empty() do
    local item = to_process:pop()
    to_delete:insert(1, item)

    if item.type == "directory" then
      for _, entry in ipairs(M.list_dir(item.path)) do
        to_process:push(entry)
      end
    end
  end

  for _, item in ipairs(to_delete:totable()) do
    if item.type == "directory" then
      M.remove_dir(item.path)
    else
      M.remove_file(item.path)
    end
  end
end

function M.create_dir(path)
  local stat = uv.fs_stat(path)
  if stat then assert(stat.type ~= "directory", "Directory already exists: " .. path) end

  local success, err = uv.fs_mkdir(path, 493)
  assert(success, err or ("Failed to create directory: " .. path))
end

function M.create_dir_recursive(path)
  local parts = vim.tbl_filter(function(part) return part ~= "" end, vim.split(path, "/"))
  local is_windows = vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1

  local current_path = is_windows and parts[1] or ""
  local start_index = is_windows and 2 or 1

  for i = start_index, #parts do
    current_path = current_path .. "/" .. parts[i]

    if not stat_exists(current_path) then M.create_dir(current_path) end
  end
end

function M.remove_dir(path)
  local stat = uv.fs_stat(path)
  assert(stat and stat.type == "directory", "Path is not a directory: " .. path)

  local success, rmdir_err = uv.fs_rmdir(path)
  assert(success, rmdir_err or ("Failed to remove directory: " .. path))
end

function M.move_path(src_path, dst_path)
  local dst_stat = uv.fs_stat(dst_path)
  assert(not dst_stat, "Destination path already exists: " .. dst_path)

  local success, rename_err = uv.fs_rename(src_path, dst_path)
  assert(success, rename_err or ("Failed to move: " .. src_path))
end

function M.copy_file(src_path, dst_path)
  local src_stat = uv.fs_stat(src_path)
  assert(src_stat and src_stat.type ~= "directory", "Cannot copy directory with copy_file: " .. src_path)

  local dst_stat = uv.fs_stat(dst_path)
  assert(not dst_stat, "Destination path already exists: " .. dst_path)

  local success, copy_err = uv.fs_copyfile(src_path, dst_path)
  assert(success, copy_err or ("Failed to copy file: " .. src_path))
end

function M.copy_recursive(src_path, dst_path)
  local src_stat = uv.fs_stat(src_path)
  if not src_stat then return end

  local dst_stat = uv.fs_stat(dst_path)
  assert(not dst_stat, "Destination path already exists: " .. dst_path)

  local stack = Stack.new()
  stack:push {
    src_path = src_path,
    dst_path = dst_path,
    type = src_stat.type,
  }

  while not stack:is_empty() do
    local item = stack:pop()

    if item.type == "directory" then
      M.create_dir_recursive(item.dst_path)

      for _, entry in ipairs(M.list_dir(item.src_path)) do
        stack:push {
          src_path = entry.path,
          dst_path = M.joinpath(item.dst_path, entry.name),
          type = entry.type,
        }
      end
    else
      local success, copy_err = uv.fs_copyfile(item.src_path, item.dst_path)
      assert(success, copy_err or ("Failed to copy file: " .. item.src_path))
    end
  end
end

function M.create(path)
  local is_directory = vim.endswith(path, "/")
  local parent_path = vim.fn.fnamemodify(path, is_directory and ":h:h" or ":h")

  M.create_dir_recursive(parent_path)

  if is_directory then
    M.create_dir(path)
  else
    M.create_file(path)
  end
end

function M.delete(path)
  M.remove_recursive(path)
  vim.schedule(function() hooks.on_delete(path) end)
end

function M.move(src_path, dst_path)
  local parent_path = vim.fn.fnamemodify(dst_path, ":h")
  M.create_dir_recursive(parent_path)
  M.move_path(src_path, dst_path)

  vim.schedule(function() hooks.on_rename(src_path, dst_path) end)
end

function M.copy(src_path, dst_path)
  local src_stat = uv.fs_stat(src_path)
  if not src_stat then return end

  local dst_stat = uv.fs_stat(dst_path)
  assert(not dst_stat, "Destination path already exists: " .. dst_path)

  local parent_path = vim.fn.fnamemodify(dst_path, ":h")
  M.create_dir_recursive(parent_path)

  if src_stat.type == "directory" then
    M.copy_recursive(src_path, dst_path)
  else
    local success, copy_err = uv.fs_copyfile(src_path, dst_path)
    assert(success, copy_err or ("Failed to copy file: " .. src_path))
  end
end

return M

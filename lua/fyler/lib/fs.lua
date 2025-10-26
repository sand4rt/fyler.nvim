local List = require "fyler.lib.structs.list"
local Stack = require "fyler.lib.structs.stack"
local config = require "fyler.config"
local hooks = require "fyler.hooks"
local util = require "fyler.lib.util"
local M = {}
local uv = vim.uv or vim.loop

M.IS_MAC = uv.os_uname().sysname == "Darwin"
M.IS_WINDOWS = uv.os_uname().version:match "Windows"
M.IS_LINUX = not (M.IS_WINDOWS or M.IS_MAC)

function M.cwd()
  return uv.cwd() or vim.fn.getcwd(0)
end

function M.normalize(path)
  return vim.fs.normalize(path)
end

function M.joinpath(...)
  return vim.fs.joinpath(...)
end

function M.abspath(path)
  return vim.fs.abspath(path)
end

function M.relpath(base, path)
  return vim.fs.relpath(base, path)
end

local function stat_exists(path)
  return not not select(1, uv.fs_stat(path))
end

local function normalize_for_compare(path)
  if not path then
    return nil
  end

  path = vim.fs.normalize(path)
  return path and path:gsub("\\", "/") or nil
end

local function is_descendant(path, parent)
  local normalized_path = normalize_for_compare(path)
  local normalized_parent = normalize_for_compare(parent)

  if not normalized_path or not normalized_parent then
    return false
  end

  if normalized_path == normalized_parent then
    return true
  end

  if normalized_parent:sub(-1) ~= "/" then
    normalized_parent = normalized_parent .. "/"
  end

  return normalized_path:sub(1, #normalized_parent) == normalized_parent
end

local function macos_trash_dir()
  return M.joinpath(uv.os_homedir(), ".Trash")
end

local function linux_trash_dirs()
  local base_dir = vim.env.XDG_DATA_HOME
  if not base_dir or base_dir == "" then
    base_dir = M.joinpath(uv.os_homedir(), ".local", "share")
  end

  local files_dir = M.joinpath(base_dir, "Trash", "files")
  local info_dir = M.joinpath(base_dir, "Trash", "info")
  return files_dir, info_dir
end

local function is_in_system_trash(path)
  if not path then
    return false
  end

  if M.IS_MAC then
    return is_descendant(path, macos_trash_dir())
  end

  if M.IS_LINUX then
    local files_dir, info_dir = linux_trash_dirs()
    return is_descendant(path, files_dir) or is_descendant(path, info_dir)
  end

  if M.IS_WINDOWS then
    local normalized_path = normalize_for_compare(path)
    -- Check for $RECYCLE.BIN as a path component, not just a substring
    -- This prevents false positives like "/projects/$recycle.bin.old/"
    return normalized_path and normalized_path:lower():match "[/\\]%$recycle%.bin[/\\]" ~= nil
  end

  return false
end

local function split_filename(filename)
  local name, ext = filename:match "^(.*)%.([^%.]+)$"
  if name and name ~= "" then
    return name, "." .. ext
  end
  return filename, ""
end

local function next_available_name(dir, filename)
  if not stat_exists(M.joinpath(dir, filename)) then
    return filename
  end

  local name, ext = split_filename(filename)
  local counter = 1

  while true do
    local candidate = string.format("%s (%d)%s", name, counter, ext)
    if not stat_exists(M.joinpath(dir, candidate)) then
      return candidate
    end
    counter = counter + 1
  end
end

local function url_encode(path)
  return path:gsub("([^%w%._~/-])", function(char)
    return string.format("%%%02X", string.byte(char))
  end)
end

local function trash_macos(path)
  local trash_dir = macos_trash_dir()
  M.create_dir_recursive(trash_dir)

  local base_name = vim.fs.basename(path)
  local target_name = next_available_name(trash_dir, base_name)
  local target_path = M.joinpath(trash_dir, target_name)

  local success, rename_err = uv.fs_rename(path, target_path)
  if not success then
    -- EXDEV (cross-device link) error - try copy+delete fallback
    if rename_err and rename_err:match "EXDEV" then
      local stat = uv.fs_stat(path)
      if stat and stat.type == "directory" then
        M.copy_recursive(path, target_path)
      else
        local copy_success, copy_err = uv.fs_copyfile(path, target_path)
        if not copy_success then
          return false, copy_err or ("Failed to copy to trash: " .. path)
        end
      end
      -- Only remove original after successful copy
      M.remove_recursive(path)
      return true
    end
    return false, rename_err or ("Failed to move to trash: " .. path)
  end

  return true
end

local function trash_linux(path)
  -- Note: This implementation follows the FreeDesktop.org Trash specification.
  -- The .trashinfo file is created before moving the file. If the process crashes
  -- between these operations, the trash may be in an inconsistent state with orphaned
  -- .trashinfo files. This is imho an acceptable tradeoff for simplicity.
  local absolute_path = M.abspath(path)
  local files_dir, info_dir = linux_trash_dirs()

  M.create_dir_recursive(files_dir)
  M.create_dir_recursive(info_dir)

  local base_name = vim.fs.basename(path)
  local target_name = next_available_name(files_dir, base_name)
  local target_path = M.joinpath(files_dir, target_name)
  local info_path = M.joinpath(info_dir, target_name .. ".trashinfo")
  local info_contents =
    string.format("[Trash Info]\nPath=%s\nDeletionDate=%s\n", url_encode(absolute_path), os.date "%Y-%m-%dT%H:%M:%S")

  local info_fd, open_err = uv.fs_open(info_path, "w", 420) -- 0644 (rw-r--r--)
  if not info_fd then
    return false, open_err or ("Failed to create trash metadata: " .. info_path)
  end

  local written, write_err = uv.fs_write(info_fd, info_contents, -1)
  uv.fs_close(info_fd)

  if not written then
    uv.fs_unlink(info_path)
    return false, write_err or ("Failed to write trash metadata: " .. info_path)
  end

  local success, rename_err = uv.fs_rename(path, target_path)
  if not success then
    -- EXDEV (cross-device link) error - try copy+delete fallback
    if rename_err and rename_err:match "EXDEV" then
      local stat = uv.fs_stat(path)
      if stat and stat.type == "directory" then
        M.copy_recursive(path, target_path)
      else
        local copy_success, copy_err = uv.fs_copyfile(path, target_path)
        if not copy_success then
          uv.fs_unlink(info_path)
          return false, copy_err or ("Failed to copy to trash: " .. path)
        end
      end
      -- Only remove original after successful copy
      M.remove_recursive(path)
      return true
    end
    uv.fs_unlink(info_path)
    return false, rename_err or ("Failed to move to trash: " .. path)
  end

  return true
end

local function ps_quote(path)
  return "'" .. path:gsub("'", "''") .. "'"
end

local function trash_windows(path)
  local absolute_path = M.abspath(path)
  local quoted_path = ps_quote(absolute_path)

  -- Wrap the operation in a timeout to prevent hanging
  local script = string.format(
    [[
$timeoutSeconds = 30;
$job = Start-Job -ScriptBlock {
  Add-Type -AssemblyName Microsoft.VisualBasic;
  $ErrorActionPreference = 'Stop';
  $item = Get-Item -LiteralPath %s;
  if ($item.PSIsContainer) {
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(%s, 'OnlyErrorDialogs', 'SendToRecycleBin');
  } else {
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(%s, 'OnlyErrorDialogs', 'SendToRecycleBin');
  }
};
$completed = Wait-Job -Job $job -Timeout $timeoutSeconds;
if ($completed) {
  $result = Receive-Job -Job $job -ErrorAction SilentlyContinue -ErrorVariable jobError;
  Remove-Job -Job $job -Force;
  if ($jobError) {
    Write-Error $jobError;
    exit 1;
  }
} else {
  Remove-Job -Job $job -Force;
  Write-Error 'Operation timed out after 30 seconds';
  exit 1;
}
]],
    quoted_path,
    quoted_path,
    quoted_path
  )

  local result = vim.fn.system {
    "powershell",
    "-NoProfile",
    "-NonInteractive",
    "-Command",
    script,
  }

  if vim.v.shell_error ~= 0 then
    -- Clean up error message for better readability
    local error_msg = result and result:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if error_msg == "" then
      error_msg = "Failed to move to recycle bin: " .. absolute_path
    end
    return false, error_msg
  end

  return true
end

local default_trash_backend = {}

function default_trash_backend.is_in_trash(path)
  return is_in_system_trash(path)
end

function default_trash_backend.move(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return false, "File or directory does not exist: " .. path
  end

  if M.IS_MAC then
    return trash_macos(path)
  end

  if M.IS_LINUX then
    return trash_linux(path)
  end

  if M.IS_WINDOWS then
    return trash_windows(path)
  end

  return false, "Unsupported platform for trash operation"
end

M._trash_backend = default_trash_backend

function M.trash(path)
  return M._trash_backend.move(path)
end

function M.set_trash_backend(backend)
  assert(type(backend) == "table", "Trash backend must be a table")
  assert(type(backend.move) == "function", "Trash backend must implement move")
  assert(type(backend.is_in_trash) == "function", "Trash backend must implement is_in_trash")

  M._trash_backend = backend
end

function M.reset_trash_backend()
  M._trash_backend = default_trash_backend
end

function M.exists(path)
  return stat_exists(path)
end

function M.reslink(link)
  local current_path = link
  local stat = uv.fs_stat(current_path)

  while stat do
    local target = uv.fs_readlink(current_path)
    if not target then
      return current_path, stat.type
    end

    current_path = target
    stat = uv.fs_stat(current_path)
  end

  return nil, nil
end

function M.listdir(path)
  local stat = uv.fs_stat(path)
  if not (stat and stat.type == "directory") then
    return {}
  end

  ---@diagnostic disable-next-line: param-type-mismatch
  local dir, open_err = uv.fs_opendir(path, nil, 1000)
  assert(dir, open_err or ("Unable to open directory: " .. path))

  local items = {}
  repeat
    local entries = uv.fs_readdir(dir)
    if entries then
      for _, entry in ipairs(entries) do
        local fullpath = M.joinpath(path, entry.name)
        local item = { name = entry.name }

        if entry.type == "link" then
          local respath, restype = M.reslink(fullpath)
          if respath and restype then
            item.type = restype
            item.path = respath
            item.link = fullpath
          else
            item.type = "file"
            item.path = fullpath
            item.link = fullpath
          end
        else
          item.type = entry.type
          item.path = fullpath
        end

        table.insert(items, item)
      end
    end
  until not entries

  uv.fs_closedir(dir)

  return items
end

function M.create_file(path)
  if stat_exists(path) then
    return
  end

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
  if not stat then
    return
  end

  local to_process = Stack.new()
  local to_delete = List.new()
  to_process:push { path = path, type = stat.type }

  while not to_process:is_empty() do
    local item = to_process:pop()
    to_delete:insert(1, item)

    if item.type == "directory" then
      for _, entry in ipairs(M.listdir(item.path)) do
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
  if stat then
    assert(stat.type ~= "directory", "Directory already exists: " .. path)
  end

  local success, err = uv.fs_mkdir(path, 493)
  assert(success, err or ("Failed to create directory: " .. path))
end

function M.create_dir_recursive(path)
  local parts = util.filter_bl(vim.split(path, "/"))
  local current_path = M.IS_WINDOWS and parts[1] or ""
  local start_index = M.IS_WINDOWS and 2 or 1

  for i = start_index, #parts do
    current_path = current_path .. "/" .. parts[i]

    if not stat_exists(current_path) then
      M.create_dir(current_path)
    end
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
  if not src_stat then
    return
  end

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

      for _, entry in ipairs(M.listdir(item.src_path)) do
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
  local should_trash = config.values and config.values.delete_to_trash
  local absolute_path = vim.fn.fnamemodify(path, ":p")
  local backend = M._trash_backend

  if should_trash and backend and not backend.is_in_trash(absolute_path) then
    local success, err = backend.move(absolute_path)
    assert(success, err or ("Failed to move to trash: " .. path))
  else
    M.remove_recursive(path)
  end

  vim.schedule(function()
    hooks.on_delete(path)
  end)
end

function M.move(src_path, dst_path)
  local parent_path = vim.fn.fnamemodify(dst_path, ":h")
  M.create_dir_recursive(parent_path)
  M.move_path(src_path, dst_path)

  vim.schedule(function()
    hooks.on_rename(src_path, dst_path)
  end)
end

function M.copy(src_path, dst_path)
  local src_stat = uv.fs_stat(src_path)
  if not src_stat then
    return
  end

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

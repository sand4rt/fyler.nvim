local Path = require "fyler.lib.path"
local hooks = require "fyler.hooks"
local util = require "fyler.lib.util"

local c = {}

function c.cwd()
  return vim.uv.cwd()
end

---@param path string
function c.ls(path)
  local _path = Path.new(path)
  if not (_path:exists() and _path:is_dir()) then
    return
  end

  local contents = {}
  ---@diagnostic disable-next-line: param-type-mismatch
  local dir = vim.uv.fs_opendir(_path:absolute(), nil, 1000)
  if not dir then
    return
  end

  local entries = vim.uv.fs_readdir(dir)
  while entries do
    vim.list_extend(
      contents,
      util.tbl_map(entries, function(e)
        local f = _path:join(e.name)
        local p, t = f:res_link()
        if e.type == "link" then
          return {
            name = e.name,
            path = p,
            type = t or "file",
            link = f:absolute(),
          }
        else
          return {
            name = e.name,
            path = f:absolute(),
            type = e.type,
          }
        end
      end)
    )

    entries = vim.uv.fs_readdir(dir)
  end

  return contents
end

function c.touch(path)
  assert(path, "path is not provided")

  local _path = Path.new(path)

  local fd = assert(vim.uv.fs_open(_path:absolute(), "a", 420))
  assert(vim.uv.fs_close(fd))
end

function c.mkdir(path, flags)
  assert(path, "path is not provided")

  local _path = Path.new(path)
  flags = flags or {}

  if flags.p then
    for _, prefix in _path:iter() do
      pcall(c.mkdir, prefix)
    end
  else
    assert(vim.uv.fs_mkdir(_path:absolute(), 493))
  end
end

local function _read_dir_iter(path)
  ---@diagnostic disable-next-line: param-type-mismatch
  local dir = vim.uv.fs_opendir(path, nil, 1000)
  if not dir then
    return function() end
  end

  local entries = vim.uv.fs_readdir(dir)
  vim.uv.fs_closedir(dir)

  if not entries then
    return function() end
  end

  local i = 0
  return function()
    i = i + 1
    if i <= #entries then
      return i, entries[i]
    end
  end
end

function c.rm(path, flags)
  assert(path, "path is not provided")

  local _path = Path.new(path)
  flags = flags or {}

  if _path:is_dir() then
    assert(flags.r, "cannot remove directory without -r flag: " .. path)

    for _, e in _read_dir_iter(_path:absolute()) do
      c.rm(_path:join(e.name):absolute(), flags)
    end

    assert(vim.uv.fs_rmdir(_path:absolute()))
  else
    assert(vim.uv.fs_unlink(_path:absolute()))
  end
end

function c.mv(src, dst)
  assert(src, "src is not provided")
  assert(dst, "dst is not provided")

  local _src = Path.new(src)
  local _dst = Path.new(dst)

  assert(_src:exists(), "source does not exist: " .. src)

  pcall(c.mkdir, _dst:parent():absolute(), { p = true })

  if _src:is_dir() then
    pcall(c.mkdir, _dst:absolute(), { p = true })

    for _, e in _read_dir_iter(_src:absolute()) do
      c.mv(_src:join(e.name):absolute(), _dst:join(e.name):absolute())
    end

    assert(vim.uv.fs_rmdir(_src:absolute()))
  else
    assert(vim.uv.fs_rename(_src:absolute(), _dst:absolute()))
  end
end

function c.cp(src, dst, flags)
  assert(src, "src is not provided")
  assert(dst, "dst is not provided")

  local _src = Path.new(src)
  local _dst = Path.new(dst)
  flags = flags or {}

  assert(_src:exists(), "source does not exist: " .. src)

  if _src:is_dir() then
    assert(flags.r, "cannot copy directory without -r flag: " .. src)

    pcall(c.mkdir, _dst:absolute(), { p = true })

    for _, e in _read_dir_iter(_src:absolute()) do
      c.cp(_src:join(e.name):absolute(), _dst:join(e.name):absolute(), flags)
    end
  else
    pcall(c.mkdir, _dst:parent():absolute(), { p = true })

    assert(vim.uv.fs_copyfile(_src:absolute(), _dst:absolute()))
  end
end

---@param path string
---@param is_dir boolean|nil
function c.create(path, is_dir)
  local _path = Path.new(path):normalize()

  c.mkdir(_path:parent():absolute(), { p = true })

  if is_dir then
    c.mkdir(_path:absolute())
  else
    c.touch(_path:absolute())
  end
end

---@param path string
function c.delete(path)
  local _path = Path.new(path)
  c.rm(_path:absolute(), { r = true })

  hooks.on_delete(_path:absolute())
end

---@param src string
---@param dst string
function c.move(src, dst)
  local _src = Path.new(src)
  local _dst = Path.new(dst)
  c.mv(_src:absolute(), _dst:absolute())

  hooks.on_rename(_src:absolute(), _dst:absolute())
end

---@param src string
---@param dst string
function c.copy(src, dst)
  c.cp(Path.new(src):absolute(), Path.new(dst):absolute(), { r = true })
end

---@param path string
function c.trash(path)
  assert(path, "path is not provided")
  local _path = Path.new(path)

  assert(_path:exists(), "path does not exist: " .. path)
  local abs_path = _path:absolute()

  if Path.is_windows() then
    local ps_script = string.format(
      [[
        $timeoutSeconds = 30;
        $job = Start-Job -ScriptBlock {
          Add-Type -AssemblyName Microsoft.VisualBasic;
          $ErrorActionPreference = 'Stop';
          $item = Get-Item -LiteralPath '%s';
          if ($item.PSIsContainer) {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory('%s', 'OnlyErrorDialogs', 'SendToRecycleBin');
          } else {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('%s', 'OnlyErrorDialogs', 'SendToRecycleBin');
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
      abs_path,
      abs_path,
      abs_path
    )

    local Process = require "fyler.lib.process"
    local proc = Process.new({
      path = "powershell",
      args = { "-NoProfile", "-NonInteractive", "-Command", ps_script },
    }):spawn()

    assert(proc.code == 0, "failed to move to recycle bin: " .. (proc:err() or ""))
  else
    local home = os.getenv "HOME"
    assert(home, "could not determine home directory")

    local trash_dir = Path.new(home):join ".Trash"
    if not trash_dir:exists() then
      c.mkdir(trash_dir:absolute(), { p = true })
    end

    local filename = vim.fn.fnamemodify(abs_path, ":t")
    local timestamp = os.date "%Y%m%d_%H%M%S"
    local name, ext = filename:match "^(.+)(%..+)$"
    if not name then
      name = filename
      ext = ""
    end

    local trash_filename = string.format("%s_%s%s", name, timestamp, ext)
    local trash_path = trash_dir:join(trash_filename)
    c.mv(abs_path, trash_path:absolute())
  end
end

local function builder(fn)
  local meta = {
    __call = function(t, ...)
      local args = { ... }
      if not vim.tbl_isempty(t.flags or {}) then
        table.insert(args, t.flags)
      end

      return fn(util.unpack(args))
    end,

    __index = function(t, k)
      return setmetatable({
        flags = util.tbl_merge_force(t.flags or {}, { [k] = true }),
      }, getmetatable(t))
    end,
  }

  return setmetatable({ flags = {} }, meta)
end

return setmetatable({}, {
  __index = function(_, k)
    assert(c[k], "command not implemented: " .. k)
    return builder(c[k])
  end,
})

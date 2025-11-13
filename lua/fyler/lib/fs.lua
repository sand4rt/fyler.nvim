local Path = require "fyler.lib.path"
local hooks = require "fyler.hooks"
local util = require "fyler.lib.util"

local c = {}

function c.cwd()
  return vim.uv.cwd()
end

---@param path string
---@param data string|string[]
function c.write(path, data)
  local _path = Path.new(path)

  c.mkdir(_path:parent():normalize(), { p = true })

  local fd = assert(vim.uv.fs_open(_path:normalize(), "w", 420))
  local bytes, err = vim.uv.fs_write(fd, data)

  if not bytes then
    assert(vim.uv.fs_close(fd))
    c.rm(_path:normalize())
    error(string.format("Failed to write to %s: %s", path, err))
  end

  assert(vim.uv.fs_close(fd))
end

---@param path string
function c.ls(path)
  local _path = Path.new(path)
  if not (_path:exists() and _path:is_dir()) then
    return
  end

  local contents = {}
  ---@diagnostic disable-next-line: param-type-mismatch
  local dir = vim.uv.fs_opendir(_path:normalize(), nil, 1000)
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
            link = f:normalize(),
          }
        else
          return {
            name = e.name,
            path = f:normalize(),
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

  local fd = assert(vim.uv.fs_open(_path:normalize(), "a", 420))
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
    assert(vim.uv.fs_mkdir(_path:normalize(), 493))
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

    for _, e in _read_dir_iter(_path:normalize()) do
      c.rm(_path:join(e.name):normalize(), flags)
    end

    assert(vim.uv.fs_rmdir(_path:normalize()))
  else
    assert(vim.uv.fs_unlink(_path:normalize()))
  end
end

function c.mv(src, dst)
  assert(src, "src is not provided")
  assert(dst, "dst is not provided")

  local _src = Path.new(src)
  local _dst = Path.new(dst)

  assert(_src:exists(), "source does not exist: " .. src)

  pcall(c.mkdir, _dst:parent():normalize(), { p = true })

  if _src:is_dir() then
    pcall(c.mkdir, _dst:normalize(), { p = true })

    for _, e in _read_dir_iter(_src:normalize()) do
      c.mv(_src:join(e.name):normalize(), _dst:join(e.name):normalize())
    end

    assert(vim.uv.fs_rmdir(_src:normalize()))
  else
    assert(vim.uv.fs_rename(_src:normalize(), _dst:normalize()))
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

    pcall(c.mkdir, _dst:normalize(), { p = true })

    for _, e in _read_dir_iter(_src:normalize()) do
      c.cp(_src:join(e.name):normalize(), _dst:join(e.name):normalize(), flags)
    end
  else
    pcall(c.mkdir, _dst:parent():normalize(), { p = true })

    assert(vim.uv.fs_copyfile(_src:normalize(), _dst:normalize()))
  end
end

---@param path string
---@param is_dir boolean|nil
function c.create(path, is_dir)
  local _path = Path.new(path)

  c.mkdir(_path:parent():normalize(), { p = true })

  if is_dir then
    c.mkdir(_path:normalize())
  else
    c.touch(_path:normalize())
  end
end

---@param path string
function c.delete(path)
  local _path = Path.new(path)
  c.rm(_path:normalize(), { r = true })

  hooks.on_delete(_path:normalize())
end

---@param src string
---@param dst string
function c.move(src, dst)
  local _src = Path.new(src)
  local _dst = Path.new(dst)
  c.mv(_src:normalize(), _dst:normalize())

  hooks.on_rename(_src:normalize(), _dst:normalize())
end

---@param src string
---@param dst string
function c.copy(src, dst)
  c.cp(Path.new(src):normalize(), Path.new(dst):normalize(), { r = true })
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

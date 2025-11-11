local util = require "fyler.lib.util"

---@class Path
---@field _original string
---@field _absolute string|nil
---@field _normalized string|nil
---@field _segments string[]|nil
local Path = {}
Path.__index = Path

Path.__call = function(self)
  return self._original
end

Path.__eq = function(a, b)
  if not (Path.is_path(a) and Path.is_path(b)) then
    return false
  end
  return a:canonical() == b:canonical()
end

Path.__tostring = function(self)
  return self._original
end

---@return boolean
function Path.is_macos()
  return vim.uv.os_uname().sysname == "Darwin"
end

---@return boolean
function Path.is_linux()
  return not (Path.is_macos() or Path.is_windows())
end

---@return boolean
function Path.is_windows()
  return vim.uv.os_uname().sysname == "Windows_NT"
end

---@return boolean
function Path.is_path(t)
  return getmetatable(t) == Path
end

---@return string
function Path.root()
  return Path.is_windows() and "" or "/"
end

---@param segments string[]
---@return Path
function Path.from_segments(segments)
  local path = "/" .. table.concat(segments, "/")
  return Path.new(path)
end

---@param path string
---@return Path
function Path.new(path)
  -- Trim whitespace
  local trimmed = string.gsub(string.gsub(path, "^%s+", ""), "%s+$", "")

  local instance = {
    _original = trimmed,
    _absolute = nil,
    _normalized = nil,
    _segments = nil,
  }

  setmetatable(instance, Path)
  return instance
end

---@return string
function Path:absolute()
  if not self._absolute then
    self._absolute = vim.fs.abspath(self._original)
  end
  return self._absolute
end

---@return string
function Path:normalize()
  if not self._normalized then
    self._normalized = vim.fs.normalize(self:absolute())
  end
  return self._normalized
end

---@return string
function Path:canonical()
  -- For canonical form, we normalize and resolve symlinks
  local norm = self:normalize()

  -- Try to resolve symlinks if it exists
  if self:exists() and self:is_link() then
    local resolved, _ = self:res_link()
    if resolved then
      return vim.fs.normalize(resolved)
    end
  end

  return norm
end

---@return string[]
function Path:segments()
  if not self._segments then
    local abs = self:normalize()
    local parts = vim.split(abs, "/", { plain = true })
    self._segments = util.filter_bl(parts)
  end
  return self._segments
end

---@return Path
function Path:parent()
  return Path.new(vim.fn.fnamemodify(self:normalize(), ":h"))
end

---@return string
function Path:basename()
  local segments = self:segments()
  return segments[#segments] or ""
end

---@return string
function Path:filename()
  local base = self:basename()
  return vim.fn.fnamemodify(base, ":r")
end

---@return string
function Path:extension()
  local base = self:basename()
  return vim.fn.fnamemodify(base, ":e")
end

---@return boolean
function Path:exists()
  return not not util.select_n(1, vim.uv.fs_stat(self:normalize()))
end

---@return uv.fs_stat.result|nil
function Path:stats()
  return util.select_n(1, vim.uv.fs_stat(self:normalize()))
end

---@return uv.fs_stat.result|nil
function Path:lstats()
  ---@diagnostic disable-next-line: param-type-mismatch
  return util.select_n(1, vim.uv.fs_lstat(self:normalize()))
end

---@return string|nil
function Path:type()
  local stat = self:lstats()
  if not stat then
    return
  end
  return stat.type
end

---@return boolean
function Path:is_link()
  return self:type() == "link"
end

---@return boolean
function Path:is_dir()
  local t = self:type()
  if t then
    return t == "directory"
  end

  -- Fallback: check if ends with separator (either / or \)
  return vim.endswith(self._original, "/") or vim.endswith(self._original, "\\")
end

---@return boolean
function Path:is_absolute()
  if Path.is_windows() then
    -- Windows: check for drive letter or UNC path
    return self._original:match "^[A-Za-z]:" or self._original:match "^\\\\"
  else
    -- Unix: check for leading /
    return vim.startswith(self._original, "/")
  end
end

---@param ref string
---@return string|nil
function Path:relative(ref)
  return vim.fs.relpath(self:normalize(), Path.new(ref):normalize())
end

---@return Path
function Path:join(...)
  return Path.new(vim.fs.joinpath(self:normalize(), ...))
end

---@param parent string
---@return boolean
function Path:is_descendant(parent)
  local parent_path = Path.new(parent)
  local self_segments = self:segments()
  local parent_segments = parent_path:segments()

  -- Can't be descendant if parent has more segments
  if #parent_segments >= #self_segments then
    return false
  end

  -- Check if all parent segments match
  for i = 1, #parent_segments do
    if self_segments[i] ~= parent_segments[i] then
      return false
    end
  end

  return true
end

---@param other string
---@return boolean
function Path:is_ancestor(other)
  return Path.new(other):is_descendant(self:normalize())
end

---@return string|nil, string|nil
function Path:res_link()
  if not self:is_link() then
    return
  end

  local result = self:normalize()
  local current = Path.new(result)
  local visited = {}

  while current:is_link() do
    -- Prevent infinite loops
    if visited[result] then
      return nil, "circular symlink"
    end
    visited[result] = true

    local read_link = vim.uv.fs_readlink(result)
    if type(read_link) ~= "string" then
      break
    end

    -- If symlink target is relative, resolve from parent directory
    if not Path.new(read_link):is_absolute() then
      local parent = current:parent():normalize()
      result = vim.fs.joinpath(parent, read_link)
    else
      result = read_link
    end

    result = vim.fs.abspath(result)
    current = Path.new(result)
  end

  local stats = Path.new(result):lstats()
  if stats then
    return result, stats.type
  else
    return result
  end
end

---@return function
function Path:iter()
  local segments = self:segments()
  local i = 0

  return function()
    i = i + 1
    if i <= #segments then
      -- Build absolute path progressively
      local path_parts = {}
      for j = 1, i do
        table.insert(path_parts, segments[j])
      end
      local target = "/" .. table.concat(path_parts, "/")
      return i, target
    end
  end
end

---@return string
function Path:original()
  return self._original
end

return Path

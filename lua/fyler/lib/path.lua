local util = require "fyler.lib.util"

---@class Path
---@field _path string
---@field _sep string
local Path = {}
Path.__index = Path

Path.__call = function(self)
  return self._path
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
  local sep = Path.is_windows() and "\\" or "/"
  local root = Path.is_windows() and "" or "/"
  local path = root .. table.concat(segments, sep)
  return Path.new(path)
end

---@param path string
---@return Path
function Path.new(path)
  -- Trim whitespace
  local trimmed = string.gsub(string.gsub(path, "^%s+", ""), "%s+$", "")

  -- Convert to absolute path immediately
  local absolute = vim.fs.abspath(trimmed)

  local instance = {
    _path = absolute,
    _sep = "/",
  }

  setmetatable(instance, Path)

  return instance
end

function Path:normalize()
  -- Remove trailing separators, but keep the path absolute
  local normalized = string.gsub(self._path, self._sep .. "+$", "")
  -- Handle root path case - don't remove the root separator
  if normalized == "" or (not Path.is_windows() and normalized == "") then
    normalized = Path.root()
  end
  return Path.new(normalized)
end

---@return Path
function Path:parent()
  return Path.new(vim.fn.fnamemodify(self._path, ":h"))
end

---@return boolean
function Path:exists()
  return not not util.select_n(1, vim.uv.fs_stat(self._path))
end

---@return uv.fs_stat.result|nil
function Path:stats()
  return util.select_n(1, vim.uv.fs_stat(self._path))
end

---@return uv.fs_stat.result|nil
function Path:lstats()
  ---@diagnostic disable-next-line: param-type-mismatch
  return util.select_n(1, vim.uv.fs_lstat(self._path))
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

  return vim.endswith(self._path, self._sep)
end

---@return string
function Path:absolute()
  -- Already absolute, just return it
  return self._path
end

---@param ref string
---@return string|nil
function Path:relative(ref)
  return vim.fs.relpath(self._path, ref)
end

---@return Path
function Path:join(...)
  return Path.new(vim.fs.joinpath(self._path, ...))
end

---@return string|nil, string|nil
function Path:res_link()
  if not self:is_link() then
    return
  end

  local result = self._path
  local current = Path.new(result)

  while current:is_link() do
    local read_link = vim.uv.fs_readlink(result)
    if type(read_link) ~= "string" then
      break
    end

    result = vim.fs.abspath(read_link)
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
  local segments = vim.split(self._path, self._sep)
  -- Remove empty first element (before root /)
  if segments[1] == "" then
    table.remove(segments, 1)
  end

  local i = 0
  local sep = self._sep
  local root = Path.root()

  return function()
    i = i + 1
    if i <= #segments then
      -- Build absolute path progressively
      local path_parts = {}
      for j = 1, i do
        table.insert(path_parts, segments[j])
      end
      local target = root .. table.concat(path_parts, sep)
      return i, target
    end
  end
end

return Path

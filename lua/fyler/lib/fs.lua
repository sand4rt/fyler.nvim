local M = {}

local DEFAULT_SYMLINK_RECURSION_LIMIT = 10

local uv = vim.uv or vim.loop
local fn = vim.fn

---Given the path to a symlink, find the first thing it points to that is not another symlink
---@param root_path string Path the link will be relative to
---@param link_path string
---@param max_depth number If depth is above this threshold, consider the link broken.
---@return string? path Path the link points to
---@return string? type File type
local function follow_symlink_recursive(root_path, link_path, max_depth)
  if max_depth ~= nil and max_depth <= 0 then
    -- If recursion limit is hit, the link is considered broken
    return link_path, nil
  end

  max_depth = max_depth or DEFAULT_SYMLINK_RECURSION_LIMIT

  local function resolve_path()
    local points_to = uv.fs_readlink(link_path)
    local is_abs_path = points_to:sub(1, 1) == "/"
    local normalized_path
    if is_abs_path then
      -- Do not change absolute paths
      normalized_path = points_to
    else
      -- Resolve path the link points to based on its own path
      -- E.g. symlink /foo/bar/baz --> ../../beat will resolve to /beat
      normalized_path = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(link_path), points_to))
    end
    return vim.fs.relpath(root_path, normalized_path) or normalized_path
  end

  link_path = resolve_path(root_path, link_path)

  local stat = uv.fs_stat(link_path)
  -- Check if broken link
  if not stat then
    return link_path, nil
  end

  if stat.type ~= "link" then
    return link_path, stat.type
  else
    return follow_symlink_recursive(root_path, link_path, max_depth - 1)
  end
end

---@return string
function M.getcwd()
  return uv.cwd() or fn.getcwd(0)
end

---@param a string
---@param b string
function M.joinpath(a, b)
  assert(a and b, "path is required")

  if vim.endswith(a, "/") then
    a = a:sub(1, -2)
  end

  if vim.startswith(b, "/") then
    b = b:sub(2)
  end

  return ("%s/%s"):format(a, b)
end

---@param path string
---@return string
function M.toabspath(path)
  return M.joinpath(M.getcwd(), path)
end

---@param path string
---@return string
function M.torelpath(path)
  return path:gsub(string.format("^%s/", M.getcwd():gsub("([^%w])", "%%%1")), ""):match(".*")
end

---@param path string
---@return table, string?
function M.listdir(path)
  assert(path, "path is required")

  local items = {}
  local fs, err = uv.fs_scandir(path)
  if not fs then
    return {}, err
  end

  while true do
    local name, type = uv.fs_scandir_next(fs)
    local links_to = nil

    if not name then
      break
    end

    if type == "link" then
      local link_path, link_type = follow_symlink_recursive(uv.cwd(), vim.fs.joinpath(path, name))
      links_to = { path = link_path, type = link_type }
    end

    table.insert(items, {
      name = name,
      type = type,
      links_to = links_to,
      path = M.joinpath(path, name),
    })
  end

  return items, nil
end

---@param path string
function M.create_fs_item(path)
  local stat = uv.fs_stat(path)
  if stat then
    return
  end

  local path_type = string.sub(path, -1) == "/" and "directory" or "file"
  if path_type == "directory" then
    if vim.fn.mkdir(path, "p") == 0 then
      return
    end
  else
    local parent_path = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(path) == 0 then
      if vim.fn.mkdir(parent_path, "p") == 0 then
        return
      end
    end

    local fd, err = uv.fs_open(path, "w", 438)
    if not fd or err then
      return
    end

    uv.fs_close(fd)
  end

  vim.notify("CREATE: " .. path, vim.log.levels.INFO)
end

---@param path string
function M.delete_fs_item(path)
  local stat, _, err = uv.fs_stat(path)

  -- Check for symlink loop. If true, delete the symlink
  if not stat and err == "ELOOP" then
    vim.fn.delete(path)
  elseif not stat then
    return
  elseif stat.type == "directory" then
    vim.fn.delete(path, "rf")
  elseif stat.type == "file" or stat.type == "link" then
    vim.fn.delete(path)
  else
    return
  end

  vim.notify("DELETE: " .. path, vim.log.levels.INFO)
end

---@param from string
---@param to string
function M.move_fs_item(from, to)
  local from_stat = uv.fs_stat(from)
  if not from_stat then
    return
  end

  local parent_dir = vim.fn.fnamemodify(to, ":h")
  local parent_stat = uv.fs_stat(parent_dir)
  if not parent_stat then
    M.create_fs_item(parent_dir .. "/")
  end

  uv.fs_rename(from, to)
  vim.notify("MOVE: " .. from .. " > " .. to, vim.log.levels.INFO)
end

return M

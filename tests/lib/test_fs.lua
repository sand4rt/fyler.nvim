local config = require "fyler.config"
local fs = require "fyler.lib.fs"
local hooks = require "fyler.hooks"
local test = require "mini.test"
local T = test.new_set()
local TEST_DATA_DIR = vim.fs.joinpath(FYLER_TESTING_DIR, "data")

local function with_trash_backend(backend, fn)
  local ok, err = pcall(function()
    fs.set_trash_backend(backend)
    fn()
  end)

  fs.reset_trash_backend()

  if not ok then
    error(err)
  end
end

local function configure_delete_to_trash(enabled)
  config.setup { delete_to_trash = enabled }
  hooks.setup(config)
end

configure_delete_to_trash(false)

local function setup_test_env()
  vim.fn.mkdir(TEST_DATA_DIR, "p")
end

local function cleanup_test_env()
  if vim.fn.isdirectory(TEST_DATA_DIR) == 1 then
    vim.fn.delete(TEST_DATA_DIR, "rf")
  end
end

T["cwd"] = function()
  local cwd = fs.cwd()
  test.expect.no_equality(cwd, nil)
  test.expect.equality(type(cwd), "string")
end

T["normalize"] = function()
  local normalized = fs.normalize "/some//path/../to/./file"
  test.expect.equality(type(normalized), "string")
  test.expect.no_equality(normalized:find "//", true)
end

T["joinpath"] = function()
  local joined = fs.joinpath("foo", "bar", "baz")
  test.expect.equality(joined, "foo/bar/baz")
end

T["abspath"] = function()
  local abs_path = fs.abspath "."
  test.expect.equality(type(abs_path), "string")
  test.expect.equality(abs_path:sub(1, 1), "/")
end

T["exists"] = function()
  setup_test_env()

  local target_path = vim.fs.joinpath(TEST_DATA_DIR, "foobar")
  vim.fn.mkdir(target_path, "p")
  test.expect.equality(fs.exists(target_path), true)

  vim.fn.delete(target_path, "rf")
  test.expect.equality(fs.exists(target_path), false)

  cleanup_test_env()
end

T["create_dir"] = function()
  setup_test_env()

  local test_dir = vim.fs.joinpath(TEST_DATA_DIR, "test_mkdir")
  fs.create_dir(test_dir)
  test.expect.equality(fs.exists(test_dir), true)
  test.expect.equality(vim.fn.isdirectory(test_dir), 1)

  cleanup_test_env()
end

T["create_dir_recursive"] = function()
  setup_test_env()

  local nested_path = vim.fs.joinpath(TEST_DATA_DIR, "a", "b", "c", "d")
  fs.create_dir_recursive(nested_path)
  test.expect.equality(fs.exists(nested_path), true)
  test.expect.equality(vim.fn.isdirectory(nested_path), 1)

  cleanup_test_env()
end

T["remove_dir"] = function()
  setup_test_env()

  local test_dir = vim.fs.joinpath(TEST_DATA_DIR, "test_rmdir")
  vim.fn.mkdir(test_dir, "p")
  test.expect.equality(fs.exists(test_dir), true)

  fs.remove_dir(test_dir)
  test.expect.equality(fs.exists(test_dir), false)

  cleanup_test_env()
end

T["listdir"] = function()
  setup_test_env()

  local file1 = vim.fs.joinpath(TEST_DATA_DIR, "file1.txt")
  local file2 = vim.fs.joinpath(TEST_DATA_DIR, "file2.txt")
  local subdir = vim.fs.joinpath(TEST_DATA_DIR, "subdir")

  vim.fn.writefile({ "content" }, file1)
  vim.fn.writefile({ "content" }, file2)
  vim.fn.mkdir(subdir, "p")

  local items = fs.listdir(TEST_DATA_DIR)
  test.expect.equality(type(items), "table")
  test.expect.equality(#items, 3)

  local names = {}
  for _, item in ipairs(items) do
    table.insert(names, item.name)
    test.expect.no_equality(item.type, nil)
    test.expect.no_equality(item.path, nil)
  end
  table.sort(names)

  test.expect.equality(names[1], "file1.txt")
  test.expect.equality(names[2], "file2.txt")
  test.expect.equality(names[3], "subdir")

  cleanup_test_env()
end

T["create_file"] = function()
  setup_test_env()

  local test_file = vim.fs.joinpath(TEST_DATA_DIR, "test_touch.txt")
  fs.create_file(test_file)
  test.expect.equality(fs.exists(test_file), true)
  test.expect.equality(vim.fn.filereadable(test_file), 1)

  fs.create_file(test_file)
  test.expect.equality(fs.exists(test_file), true)

  cleanup_test_env()
end

T["remove_file"] = function()
  setup_test_env()

  local test_file = vim.fs.joinpath(TEST_DATA_DIR, "test_rm.txt")
  vim.fn.writefile({ "content" }, test_file)
  test.expect.equality(fs.exists(test_file), true)

  fs.remove_file(test_file)
  test.expect.equality(fs.exists(test_file), false)

  cleanup_test_env()
end

T["remove_recursive"] = function()
  setup_test_env()

  local nested_dir = vim.fs.joinpath(TEST_DATA_DIR, "nested", "deep", "structure")
  vim.fn.mkdir(nested_dir, "p")

  local file1 = vim.fs.joinpath(TEST_DATA_DIR, "nested", "file1.txt")
  local file2 = vim.fs.joinpath(nested_dir, "file2.txt")
  vim.fn.writefile({ "content" }, file1)
  vim.fn.writefile({ "content" }, file2)

  local root_path = vim.fs.joinpath(TEST_DATA_DIR, "nested")
  test.expect.equality(fs.exists(root_path), true)

  fs.remove_recursive(root_path)
  test.expect.equality(fs.exists(root_path), false)

  cleanup_test_env()
end

T["move_path"] = function()
  setup_test_env()

  local src_file = vim.fs.joinpath(TEST_DATA_DIR, "src.txt")
  local dst_file = vim.fs.joinpath(TEST_DATA_DIR, "dst.txt")

  vim.fn.writefile({ "test content" }, src_file)
  test.expect.equality(fs.exists(src_file), true)

  fs.move_path(src_file, dst_file)
  test.expect.equality(fs.exists(src_file), false)
  test.expect.equality(fs.exists(dst_file), true)

  local content = vim.fn.readfile(dst_file)
  test.expect.equality(content[1], "test content")

  cleanup_test_env()
end

T["copy_file"] = function()
  setup_test_env()

  local src_file = vim.fs.joinpath(TEST_DATA_DIR, "src.txt")
  local dst_file = vim.fs.joinpath(TEST_DATA_DIR, "dst.txt")

  vim.fn.writefile({ "test content" }, src_file)
  test.expect.equality(fs.exists(src_file), true)

  fs.copy_file(src_file, dst_file)
  test.expect.equality(fs.exists(src_file), true)
  test.expect.equality(fs.exists(dst_file), true)

  local content = vim.fn.readfile(dst_file)
  test.expect.equality(content[1], "test content")

  cleanup_test_env()
end

T["copy_recursive"] = function()
  setup_test_env()

  local src_dir = vim.fs.joinpath(TEST_DATA_DIR, "src_dir")
  local src_subdir = vim.fs.joinpath(src_dir, "subdir")
  vim.fn.mkdir(src_subdir, "p")

  local file1 = vim.fs.joinpath(src_dir, "file1.txt")
  local file2 = vim.fs.joinpath(src_subdir, "file2.txt")
  vim.fn.writefile({ "content1" }, file1)
  vim.fn.writefile({ "content2" }, file2)

  local dst_dir = vim.fs.joinpath(TEST_DATA_DIR, "dst_dir")
  fs.copy_recursive(src_dir, dst_dir)

  test.expect.equality(fs.exists(src_dir), true)
  test.expect.equality(fs.exists(dst_dir), true)
  test.expect.equality(fs.exists(vim.fs.joinpath(dst_dir, "file1.txt")), true)
  test.expect.equality(fs.exists(vim.fs.joinpath(dst_dir, "subdir", "file2.txt")), true)

  local content1 = vim.fn.readfile(vim.fs.joinpath(dst_dir, "file1.txt"))
  local content2 = vim.fn.readfile(vim.fs.joinpath(dst_dir, "subdir", "file2.txt"))
  test.expect.equality(content1[1], "content1")
  test.expect.equality(content2[1], "content2")

  cleanup_test_env()
end

T["create"] = function()
  setup_test_env()

  local test_file = vim.fs.joinpath(TEST_DATA_DIR, "deep", "nested", "file.txt")
  fs.create(test_file)
  test.expect.equality(fs.exists(test_file), true)
  test.expect.equality(vim.fn.filereadable(test_file), 1)

  local test_dir = vim.fs.joinpath(TEST_DATA_DIR, "deep", "nested", "dir/")
  fs.create(test_dir)
  test.expect.equality(fs.exists(test_dir), true)
  test.expect.equality(vim.fn.isdirectory(test_dir), 1)

  cleanup_test_env()
end

T["copy"] = function()
  setup_test_env()

  local src_file = vim.fs.joinpath(TEST_DATA_DIR, "src.txt")
  local dst_file = vim.fs.joinpath(TEST_DATA_DIR, "nested", "dst.txt")
  vim.fn.writefile({ "content" }, src_file)

  fs.copy(src_file, dst_file)
  test.expect.equality(fs.exists(src_file), true)
  test.expect.equality(fs.exists(dst_file), true)

  local src_dir = vim.fs.joinpath(TEST_DATA_DIR, "src_dir")
  local dst_dir = vim.fs.joinpath(TEST_DATA_DIR, "nested", "dst_dir")
  vim.fn.mkdir(src_dir, "p")
  vim.fn.writefile({ "dir_content" }, vim.fs.joinpath(src_dir, "file.txt"))

  fs.copy(src_dir, dst_dir)
  test.expect.equality(fs.exists(src_dir), true)
  test.expect.equality(fs.exists(dst_dir), true)
  test.expect.equality(fs.exists(vim.fs.joinpath(dst_dir, "file.txt")), true)

  cleanup_test_env()
end

T["errors"] = function()
  setup_test_env()

  local test_file = vim.fs.joinpath(TEST_DATA_DIR, "not_dir.txt")
  vim.fn.writefile({ "content" }, test_file)

  test.expect.error(function()
    fs.remove_file "/non/existent/file"
  end)

  local src = vim.fs.joinpath(TEST_DATA_DIR, "src.txt")
  local dst = vim.fs.joinpath(TEST_DATA_DIR, "dst.txt")
  vim.fn.writefile({ "src" }, src)
  vim.fn.writefile({ "dst" }, dst)

  test.expect.error(function()
    fs.copy_file(src, dst)
  end)

  cleanup_test_env()
end

T["reslink"] = function()
  setup_test_env()

  local target_file = vim.fs.joinpath(TEST_DATA_DIR, "target.txt")
  vim.fn.writefile({ "content" }, target_file)

  local respath, restype = fs.reslink(target_file)
  test.expect.equality(respath, target_file)
  test.expect.equality(restype, "file")

  cleanup_test_env()
end

if fs.IS_LINUX then
  T["delete_to_trash moves files into XDG trash"] = function()
    setup_test_env()

    local original_xdg = vim.env.XDG_DATA_HOME
    local ok, err = pcall(function()
      local xdg_home = vim.fs.joinpath(TEST_DATA_DIR, "xdg")
      vim.env.XDG_DATA_HOME = xdg_home

      configure_delete_to_trash(true)

      local source_file = vim.fs.joinpath(TEST_DATA_DIR, "sample.txt")
      vim.fn.writefile({ "dummy" }, source_file)

      fs.delete(source_file)
      test.expect.equality(fs.exists(source_file), false)

      local trash_files = vim.fs.joinpath(xdg_home, "Trash", "files")
      local trash_info = vim.fs.joinpath(xdg_home, "Trash", "info")
      local trashed_file = vim.fs.joinpath(trash_files, "sample.txt")
      local trashed_info = vim.fs.joinpath(trash_info, "sample.txt.trashinfo")

      test.expect.equality(fs.exists(trashed_file), true)
      test.expect.equality(fs.exists(trashed_info), true)
    end)

    configure_delete_to_trash(false)
    vim.env.XDG_DATA_HOME = original_xdg
    cleanup_test_env()

    if not ok then
      error(err)
    end
  end

  T["delete_to_trash permanently removes items already in trash"] = function()
    setup_test_env()

    local original_xdg = vim.env.XDG_DATA_HOME
    local ok, err = pcall(function()
      local xdg_home = vim.fs.joinpath(TEST_DATA_DIR, "xdg")
      vim.env.XDG_DATA_HOME = xdg_home

      configure_delete_to_trash(true)

      local trash_files = vim.fs.joinpath(xdg_home, "Trash", "files")
      vim.fn.mkdir(trash_files, "p")

      local existing = vim.fs.joinpath(trash_files, "existing.txt")
      vim.fn.writefile({ "content" }, existing)
      test.expect.equality(fs.exists(existing), true)

      fs.delete(existing)
      test.expect.equality(fs.exists(existing), false)
    end)

    configure_delete_to_trash(false)
    vim.env.XDG_DATA_HOME = original_xdg
    cleanup_test_env()

    if not ok then
      error(err)
    end
  end
end

T["delete_to_trash uses configured backend when enabled"] = function()
  setup_test_env()

  configure_delete_to_trash(true)

  local test_file = vim.fs.joinpath(TEST_DATA_DIR, "stubbed.txt")
  vim.fn.writefile({ "content" }, test_file)

  local moved_path
  local backend = {
    move = function(path)
      moved_path = path
      vim.fn.delete(path)
      return true
    end,
    is_in_trash = function()
      return false
    end,
  }

  with_trash_backend(backend, function()
    fs.delete(test_file)
  end)

  test.expect.equality(moved_path, vim.fn.fnamemodify(test_file, ":p"))
  test.expect.equality(fs.exists(test_file), false)

  configure_delete_to_trash(false)
  cleanup_test_env()
end

T["delete_to_trash bypasses backend when disabled"] = function()
  setup_test_env()

  configure_delete_to_trash(false)

  local test_file = vim.fs.joinpath(TEST_DATA_DIR, "noop.txt")
  vim.fn.writefile({ "content" }, test_file)

  local backend = {
    move = function()
      error "trash backend should not be invoked when delete_to_trash is disabled"
    end,
    is_in_trash = function()
      return false
    end,
  }

  with_trash_backend(backend, function()
    fs.delete(test_file)
  end)

  test.expect.equality(fs.exists(test_file), false)

  cleanup_test_env()
end

T["delete_to_trash permanently deletes items already flagged as trashed"] = function()
  setup_test_env()

  configure_delete_to_trash(true)

  local test_file = vim.fs.joinpath(TEST_DATA_DIR, "already_trashed.txt")
  vim.fn.writefile({ "content" }, test_file)

  local backend = {
    move = function()
      error "trash backend move should not be called for paths already in trash"
    end,
    is_in_trash = function()
      return true
    end,
  }

  with_trash_backend(backend, function()
    fs.delete(test_file)
  end)

  test.expect.equality(fs.exists(test_file), false)

  configure_delete_to_trash(false)
  cleanup_test_env()
end

return T

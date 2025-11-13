local test = require "mini.test"

local T = test.new_set {
  hooks = {
    pre_case = function()
      vim.fn.mkdir(FYLER_TESTING_DIR_DATA)
    end,

    post_case = function()
      vim.fn.delete(FYLER_TESTING_DIR_DATA, "rf")
    end,
  },
}

local Path = require "fyler.lib.path"
local fs = require "fyler.lib.fs"

T["touch"] = function()
  local _path = Path.new(FYLER_TESTING_DIR_DATA):join "foobar.txt"
  test.expect.equality(_path:exists(), false)

  fs.touch(_path:normalize())
  test.expect.equality(_path:exists(), true)
end

T["mkdir"] = function()
  local _path = Path.new(FYLER_TESTING_DIR_DATA):join "foobar"
  test.expect.equality(_path:exists(), false)

  fs.mkdir(_path:normalize())
  test.expect.equality(_path:exists(), true)
  test.expect.equality(_path:is_dir(), true)
end

T["mkdir.p"] = function()
  local _path = Path.new(FYLER_TESTING_DIR_DATA):join "foo/bar/baz"
  test.expect.equality(_path:exists(), false)

  fs.mkdir.p(_path:normalize())
  test.expect.equality(_path:exists(), true)
  test.expect.equality(_path:is_dir(), true)
end

T["rm"] = function()
  local _path = Path.new(FYLER_TESTING_DIR_DATA):join "foobar.txt"
  test.expect.equality(_path:exists(), false)

  fs.touch(_path:normalize())
  test.expect.equality(_path:exists(), true)

  fs.rm(_path:normalize())
  test.expect.equality(_path:exists(), false)
end

T["rm.r"] = function()
  local _path = Path.new(FYLER_TESTING_DIR_DATA):join "foo/bar/baz"
  test.expect.equality(_path:exists(), false)

  fs.mkdir.p(_path:normalize())
  test.expect.equality(_path:exists(), true)
  test.expect.equality(_path:is_dir(), true)

  fs.rm.r(_path:normalize())
  test.expect.equality(_path:exists(), false)
end

T["mv"] = function()
  local _src = Path.new(FYLER_TESTING_DIR_DATA):join "foo/bar/baz"
  test.expect.equality(_src:exists(), false)

  fs.mkdir.p(_src:normalize())
  test.expect.equality(_src:exists(), true)
  test.expect.equality(_src:is_dir(), true)

  local _dst = Path.new(FYLER_TESTING_DIR_DATA):join "buz"
  test.expect.equality(_dst:exists(), false)

  fs.mv(_src:parent():parent():normalize(), _dst:normalize())
  test.expect.equality(_dst:exists(), true)
  test.expect.equality(_dst:is_dir(), true)
end

T["cp"] = function()
  local _src = Path.new(FYLER_TESTING_DIR_DATA):join "foo.txt"
  test.expect.equality(_src:exists(), false)

  fs.touch(_src:normalize())
  test.expect.equality(_src:exists(), true)

  local _dst = Path.new(FYLER_TESTING_DIR_DATA):join "bar.txt"
  test.expect.equality(_dst:exists(), false)

  fs.cp(_src:normalize(), _dst:normalize())
  test.expect.equality(_dst:exists(), true)
end

T["cp.r"] = function()
  local _src = Path.new(FYLER_TESTING_DIR_DATA):join "foo/bar/baz"
  test.expect.equality(_src:exists(), false)

  fs.mkdir.p(_src:normalize())
  test.expect.equality(_src:exists(), true)
  test.expect.equality(_src:is_dir(), true)

  local _dst = Path.new(FYLER_TESTING_DIR_DATA):join "buz"
  test.expect.equality(_dst:exists(), false)

  fs.cp.r(_src:parent():parent():normalize(), _dst:normalize())
  test.expect.equality(_dst:exists(), true)
  test.expect.equality(_dst:is_dir(), true)
end

T["create[directory]"] = function()
  local _path = Path.new(FYLER_TESTING_DIR_DATA):join "foobar"
  test.expect.equality(_path:exists(), false)

  fs.create(_path:normalize(), true)
  test.expect.equality(_path:exists(), true)
  test.expect.equality(_path:is_dir(), true)
end

T["create[file]"] = function()
  local _path = Path.new(FYLER_TESTING_DIR_DATA):join "foobar.txt"
  test.expect.equality(_path:exists(), false)

  fs.create(_path:normalize())
  test.expect.equality(_path:exists(), true)
  test.expect.equality(_path:is_dir(), false)
end

return T

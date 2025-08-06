local uv = vim.loop or vim.uv

local FYLER_TESTING_DIR = ".tests/repos/"

---@param path string
---@return boolean
local function path_exists(path)
  local _, err = uv.fs_stat(path)
  return err == nil
end

---@param repo string
local function ensure_install(repo)
  local name = repo:match("/(.*)$")
  local install_path = FYLER_TESTING_DIR .. name

  if not path_exists(install_path) then
    print("[FYLER.NVIM]: Cloning '" .. repo .. "' into " .. install_path)
    vim.system({ "git", "clone", "--depth=1", "git@github.com:" .. repo .. ".git", install_path }):wait()

    if vim.v.shell_error > 0 then return print("[FYLER.NVIM]: Failed to clone '" .. repo .. "'") end
  end

  vim.opt.runtimepath:prepend(install_path)
  print("[FYLER.NVIM]: '" .. repo .. "' Added to runtime path")
end

local function run_tests()
  ensure_install("echasnovski/mini.test")

  vim.opt.runtimepath:prepend(".")

  print("[FYLER.NVIM]: Running tests")
  print("===========================")

  require("mini.test").run {
    collect = {
      find_files = function() return vim.fn.globpath("tests", "**/test_*.lua", true, true) end,
    },
  }
end

run_tests()

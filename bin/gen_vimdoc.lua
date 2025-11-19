local uv = vim.loop or vim.uv

FYLER_TESTING_DIR = vim.fs.joinpath(vim.uv.cwd(), ".tests")

---@param path string
---@return boolean
local function path_exists(path)
  local _, err = uv.fs_stat(path)
  return err == nil
end

---@param repo string
local function ensure_install(repo)
  local name = repo:match "/(.*)$"
  local install_path = vim.fs.joinpath(FYLER_TESTING_DIR, "repos", name)

  if not path_exists(install_path) then
    vim.system({ "git", "clone", "--depth=1", "git@github.com:" .. repo .. ".git", install_path }):wait()

    if vim.v.shell_error > 0 then
      return print("[FYLER.NVIM]: Failed to clone '" .. repo .. "'")
    end
  end

  vim.opt.runtimepath:prepend(install_path)
end

local function run_tests()
  ensure_install "nvim-mini/mini.doc"

  vim.opt.runtimepath:prepend "."

  local minidoc = require "mini.doc"
  minidoc.setup()

  minidoc.generate(
    {
      "lua/fyler.lua",
      "lua/fyler/config.lua",
    },
    "doc/fyler.txt",
    {
      hooks = {
        file = function() end,
        sections = {
          ["@signature"] = function(s)
            s:remove()
          end,
          ["@return"] = function(s)
            s.parent:clear_lines()
          end,
          ["@alias"] = function(s)
            s.parent:clear_lines()
          end,
          ["@class"] = function(s)
            s.parent:clear_lines()
          end,
          ["@param"] = function(s)
            s.parent:clear_lines()
          end,
        },
      },
    }
  )
end

run_tests()

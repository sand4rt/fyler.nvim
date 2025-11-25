local MiniTest = require "mini.test"
local util = require "tests.util"

local child = util.new_child_neovim()

local eq = MiniTest.expect.equality

local dir_data = util.get_dir "data"

local T = MiniTest.new_set {
  parametrize = {
    { "float" },
    { "replace" },
    { "split_left" },
    { "split_left_most" },
    { "split_above" },
    { "split_above_all" },
    { "split_right" },
    { "split_right_most" },
    { "split_below" },
    { "split_below_all" },
  },
  hooks = {
    pre_case = function()
      child.setup()
      child.set_size(18, 70)
      child.load("fyler", {
        integrations = { icon = "none" },
        views = { finder = { git_status = { enabled = false } } },
      })

      child.o.laststatus = 3
      child.o.showtabline = 0
      child.o.cmdheight = 0

      vim.fn.mkdir(dir_data)
      vim.uv.fs_close(assert(vim.uv.fs_open(vim.fs.joinpath(dir_data, "test-file"), "a", 420)))
    end,
    post_case = function()
      child.stop()

      vim.fn.delete(dir_data, "rf")
    end,
  },
}

T["open and close"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  eq(child.o.filetype, "fyler")

  child.dbg_screen()

  local lines = child.get_lines(0, 0, -1, false)
  eq(#lines, 1)
  eq(lines[1]:match "/%d+%s(.*)$", "test-file")

  child.type_keys "q"

  eq(child.o.filetype, "")
end

T["create"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  child.set_lines(0, -1, -1, false, { "new-file", "new-dir/" })
  child.dbg_screen()
  child.cmd [[ write ]]
  child.dbg_screen()

  local lines = child.api.nvim_buf_get_lines(0, 0, -1, false)
  -- vim.print(child.o.filetype, lines)
  -- eq(lines[1], "CREATE new-dir")
  -- eq(lines[2], "CREATE new-file")
  child.type_keys "y"

  vim.uv.sleep(50)

  child.dbg_screen()
end

T["delete"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  child.set_lines(0, 0, -1, false, { "" })
  child.dbg_screen()
  child.cmd [[ write ]]
  child.dbg_screen()

  local lines = child.api.nvim_buf_get_lines(0, 0, -1, false)
  -- vim.print(child.o.filetype, lines)
  -- eq(lines[1], "DELETE test-file")
  child.type_keys "y"

  vim.uv.sleep(50)

  child.dbg_screen()
end

T["move"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  local updated_str = child.get_lines(0, 0, -1, false)[1]:gsub("test", "move")
  child.set_lines(0, 0, -1, false, { updated_str })
  child.dbg_screen()
  child.cmd [[ write ]]
  child.dbg_screen()

  local lines = child.api.nvim_buf_get_lines(0, 0, -1, false)
  eq(lines[1], "MOVE test-file > move-file")
  child.type_keys "y"

  vim.uv.sleep(50)

  child.dbg_screen()
end

T["copy"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  local updated_str = child.get_lines(0, 0, -1, false)[1]:gsub("test", "copy")
  child.set_lines(0, -1, -1, false, { updated_str })
  child.dbg_screen()
  child.cmd [[ write ]]
  child.dbg_screen()

  local lines = child.api.nvim_buf_get_lines(0, 0, -1, false)
  eq(lines[1], "COPY test-file > copy-file")
  child.type_keys "y"

  vim.uv.sleep(50)

  child.dbg_screen()
end

return T

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
      vim.fn.mkdir(vim.fs.joinpath(dir_data, "test-dir"))
      vim.fn.writefile({ "test-deep-file content" }, vim.fs.joinpath(dir_data, "test-dir", "test-deep-file"), "a")
      vim.fn.writefile({ "test-file content" }, vim.fs.joinpath(dir_data, "test-file"), "a")
    end,
    post_case = function()
      child.stop()

      vim.fn.delete(dir_data, "rf")
    end,
  },
}

T["mappings"] = MiniTest.new_set {}

T["mappings"]["Select"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  child.dbg_screen()

  child.type_keys "<Enter>"

  vim.uv.sleep(50)

  local lines = child.get_lines(0, 0, -1, false)

  eq(lines[1]:match "/%d+%s(.*)$", "test-dir")
  eq(lines[2]:match "/%d+%s(.*)$", "test-deep-file")
  eq(lines[3]:match "/%d+%s(.*)$", "test-file")

  child.dbg_screen()
  child.type_keys "<Enter>"

  vim.uv.sleep(50)

  local lines = child.get_lines(0, 0, -1, false)
  eq(lines[1]:match "/%d+%s(.*)$", "test-dir")
  eq(lines[2]:match "/%d+%s(.*)$", "test-file")

  child.dbg_screen()
end

T["mappings"]["SelectSplit"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  child.dbg_screen()

  child.type_keys "G-"

  eq(child.get_lines(0, 0, -1, false), { "test-file content" })

  child.dbg_screen()
end

T["mappings"]["SelectVSplit"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  child.dbg_screen()
  child.type_keys "G|"

  eq(child.get_lines(0, 0, -1, false), { "test-file content" })

  child.dbg_screen()
end

T["mappings"]["SelectTab"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  child.dbg_screen()
  child.type_keys "G<C-t>"

  eq(child.get_lines(0, 0, -1, false), { "test-file content" })

  child.dbg_screen()
end

T["mappings"]["GotoParent"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], vim.fs.joinpath(dir_data, "test-dir"), kind))

  vim.uv.sleep(50)

  child.dbg_screen()
  child.type_keys "^"

  vim.uv.sleep(50)

  child.dbg_screen()

  local lines = child.get_lines(0, 0, -1, false)

  eq(lines[1]:match "/%d+%s(.*)$", "test-dir")
  eq(lines[2]:match "/%d+%s(.*)$", "test-file")
end

T["mappings"]["GotoCwd"] = function(kind)
  -- NOTE: For some reason if doing cd first then fyler will not open
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], vim.fs.joinpath(dir_data, "test-dir"), kind))
  child.cmd(string.format([[ cd %s ]], dir_data))

  vim.uv.sleep(50)

  child.dbg_screen()
  child.type_keys "="

  vim.uv.sleep(50)

  child.dbg_screen()

  local lines = child.get_lines(0, 0, -1, false)

  eq(lines[1]:match "/%d+%s(.*)$", "test-dir")
  eq(lines[2]:match "/%d+%s(.*)$", "test-file")
end

T["mappings"]["GotoNode"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  child.dbg_screen()
  child.type_keys "."

  vim.uv.sleep(50)

  child.dbg_screen()

  local lines = child.get_lines(0, 0, -1, false)

  eq(lines[1]:match "/%d+%s(.*)$", "test-deep-file")
end

T["mappings"]["CollapseAll"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  child.dbg_screen()
  child.type_keys "<Enter>"

  vim.uv.sleep(50)

  child.dbg_screen()
  child.type_keys "j<Bs>"

  vim.uv.sleep(50)

  child.dbg_screen()

  local lines = child.get_lines(0, 0, -1, false)
  eq(lines[1]:match "/%d+%s(.*)$", "test-dir")
  eq(lines[2]:match "/%d+%s(.*)$", "test-file")
end

T["mappings"]["CollapseNode"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  child.dbg_screen()
  child.type_keys "<Enter>"

  vim.uv.sleep(50)

  child.dbg_screen()
  child.type_keys "j<Bs>"

  vim.uv.sleep(50)

  child.dbg_screen()

  local lines = child.get_lines(0, 0, -1, false)
  eq(lines[1]:match "/%d+%s(.*)$", "test-dir")
  eq(lines[2]:match "/%d+%s(.*)$", "test-file")
end

T["synchronize"] = function(kind)
  child.cmd(string.format([[ Fyler dir=%s kind=%s ]], dir_data, kind))

  vim.uv.sleep(50)

  child.type_keys "<Enter>"

  vim.uv.sleep(50)

  local lines = child.get_lines(0, 0, -1, false)
  lines[2] = lines[2]:gsub("test", "move")
  local copy_line = lines[1]:gsub("test", "copy")
  table.insert(lines, copy_line)
  table.insert(lines, "new-dir/")
  table.insert(lines, "new-file")
  table.remove(lines, 3)

  child.set_lines(0, 0, -1, false, lines)
  child.cmd [[ write ]]
  child.dbg_screen()

  local lines = child.get_lines(0, 0, -1, false)
  table.sort(lines)

  eq(lines[1], "COPY   test-dir > copy-dir")
  eq(lines[2], "CREATE new-dir")
  eq(lines[3], "CREATE new-file")
  eq(lines[4], "DELETE test-file")
  eq(lines[5], "MOVE   test-dir/test-deep-file > test-dir/move-deep-file")

  child.type_keys "y"

  vim.uv.sleep(50)

  child.dbg_screen()
end

return T

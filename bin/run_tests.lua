local get_dir = dofile("bin/setup_deps.lua").get_dir

vim.opt.runtimepath:prepend "."
vim.opt.runtimepath:prepend(vim.fs.joinpath(get_dir "repo", "mini.test"))

require("mini.test").run {
  collect = {
    find_files = function()
      return vim.fn.globpath("tests", "**/test_*.lua", true, true)
    end,
  },
}

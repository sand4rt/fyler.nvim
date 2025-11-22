local temp = vim.env.FYLER_TEMP_DIR or vim.fs.joinpath(vim.uv.cwd(), ".temp")

for _, dep in ipairs {
  "mini.doc",
  "mini.icons",
  "nvim-web-devicons",
  "mini.test",
} do
  local path = vim.fs.joinpath(temp, "repo", dep)
  if vim.fn.isdirectory(path) == 1 then
    vim.opt.runtimepath:prepend(path)
  end
end

vim.opt.runtimepath:prepend "."

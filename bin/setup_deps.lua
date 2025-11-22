local M = {}

function M.get_dir(name)
  return vim.fs.joinpath(vim.env.FYLER_TEMP_DIR or vim.fs.joinpath(vim.uv.cwd(), ".temp"), name)
end

do
  assert(vim.fn.executable "git" == 1, "git not installed!")

  local dir_repo = M.get_dir "repo"

  for _, dep in ipairs {
    "nvim-mini/mini.doc",
    "nvim-mini/mini.test",
    "nvim-mini/mini.icons",
    "nvim-tree/nvim-web-devicons",
  } do
    local dest = vim.fs.joinpath(dir_repo, dep:match "/(.*)$")
    if vim.fn.isdirectory(dest) ~= 1 then
      print("[Fyler.nvim] cloning " .. dep)
      vim.system({ "git", "clone", "--depth=1", "https://github.com/" .. dep .. ".git", dest }):wait()
      if vim.v.shell_error > 0 then
        print("[Fyler.nvim] clone failed for repo " .. dep)
      end
    end
  end
end

return M

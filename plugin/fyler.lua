if vim.g.loaded_fyler == 1 then
  return
end
vim.g.loaded_fyler = 1

local highlights = {
  FylerNormal = { default = true, link = 'Normal' },
  FylerBorder = { default = true, link = 'FloatBorder' },
  FylerTitle = { default = true, link = 'Directory' },
  FylerSuccess = { default = true, link = 'String' },
  FylerFailure = { default = true, link = 'Error' },
  FylerWarning = { default = true, link = 'Constant' },
  FylerHiddenCursor = { default = true, nocombine = true, blend = 100 },
}

for k, v in pairs(highlights) do
  vim.api.nvim_set_hl(0, k, v)
end

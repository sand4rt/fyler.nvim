local a = require("fyler.lib.async")

local M = {}

local api = vim.api

M.is_valid_bufnr = a.wrap(vim.schedule_wrap(function(bufnr, cb)
  -- This means provided "bufnr" is a "nil" value and we are getting only one argument which is the callback
  if type(bufnr) == "function" then
    bufnr(false)
  else
    cb(type(bufnr) == "number" and api.nvim_buf_is_valid(bufnr))
  end
end))

M.is_valid_winid = a.wrap(vim.schedule_wrap(function(winid, cb)
  -- This means provided "winid" is a "nil" value and we are getting only one argument which is the callback
  if type(winid) == "function" then
    winid(false)
  else
    cb(type(winid) == "number" and api.nvim_win_is_valid(winid))
  end
end))

M.await_schedule = a.wrap(vim.schedule)

return M

local can_log = vim.env.FYLER_LOG_ENABLE or false
local logger = {}

local notify = vim.notify
local levels = vim.log.levels

---@param args any
function logger.debug(args)
  if not can_log then
    return
  end

  print(vim.inspect(args))
end

---@param msg string
logger.info = vim.schedule_wrap(function(msg)
  notify(msg, levels.INFO, { title = "Fyler.nvim" })
end)

---@param msg string
logger.warn = vim.schedule_wrap(function(msg)
  notify(msg, levels.WARN, { title = "Fyler.nvim" })
end)

---@param msg string
logger.error = vim.schedule_wrap(function(msg)
  notify(msg, levels.ERROR, { title = "Fyler.nvim" })
end)

return logger

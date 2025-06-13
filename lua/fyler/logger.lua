local can_log = vim.env.FYLER_LOG_ENABLE or false
local logger = {}

---@param args any
logger.debug = function(args)
  if not can_log then
    return
  end

  print(vim.inspect(args))
end

return logger

local fn = vim.fn

local icon_providers = {
  ---@return string?, string?
  ["none"] = function()
    return "", ""
  end,
  ---@param type string
  ---@param _ string
  ---@return string?, string?
  ["minimal"] = function(type, _)
    if type == "directory" then
      return "D", "FylerFSDirectory"
    elseif type == "file" then
      return "F", "FylerFSFile"
    else
      return "*", ""
    end
  end,
  ---@param type string
  ---@param name string
  ---@return string?, string?
  ["mini-icons"] = function(type, name)
    local success, miniicons = pcall(require, "mini.icons")
    if not success then
      return nil, nil
    end

    return miniicons.get(type, name)
  end,
  ---@param type string
  ---@param name string
  ---@return string?, string?
  ["nvim-web-devicons"] = function(type, name)
    local success, devicons = pcall(require, "nvim-web-devicons")
    if not success then
      return nil, nil
    end

    local icon, hl = devicons.get_icon(name, fn.fnamemodify(name, ":e"))
    icon = (type == "directory" and "" or (icon or ""))
    hl = hl or (type == "directory" and "Fylerblue" or "")
    return icon, hl
  end,
}

return setmetatable({}, {
  __index = function(_, key)
    local icon_provider = icon_providers[key]
    if not icon_provider then
      icon_provider = require("fyler.integrations.icon.default")
      vim.notify(string.format("(fyler.nvim) Invalid `icon_provider` `%s`. Switch to `default`", key))
    end

    return function(...)
      local success, icon, hl = pcall(icon_provider, ...)
      if not success then
        return " ", ""
      end

      return icon, hl
    end
  end,
})

local api = vim.api

local M = {}

---@param dec integer
local function to_hex(dec)
  return string.format("%06X", math.max(0, math.min(0xFFFFFF, math.floor(dec))))
end

-- https://github.com/NeogitOrg/neogit/blob/1b4f44374f97d9262caa680e41ecbebcaf1553bd/lua/neogit/lib/hl.lua#L34
---@param name string
---@return string|nil
local function get_fg(name)
  local color = vim.api.nvim_get_hl(0, { name = name })
  if color["link"] then
    return get_fg(color["link"])
  elseif color["reverse"] and color["bg"] then
    return "#" .. to_hex(color["bg"])
  elseif color["fg"] then
    return "#" .. to_hex(color["fg"])
  end
end

-- https://github.com/NeogitOrg/neogit/blob/1b4f44374f97d9262caa680e41ecbebcaf1553bd/lua/neogit/lib/hl.lua#L47
---@param name string
---@return string|nil
local function get_bg(name)
  local color = vim.api.nvim_get_hl(0, { name = name })
  if color["link"] then
    return get_bg(color["link"])
  elseif color["reverse"] and color["fg"] then
    return "#" .. to_hex(color["fg"])
  elseif color["bg"] then
    return "#" .. to_hex(color["bg"])
  end
end

local function make_palette()
  -- stylua: ignore start
  return {
    bg     = get_bg("Normal"),
    fg     = get_fg("Normal"),
    red    = get_fg("Error"),
    blue   = get_fg("Directory"),
    green  = get_fg("String"),
    yellow = get_fg("WarningMsg"),
  }
  -- stylua: ignore end
end

function M.setup()
  local palette = make_palette()

  -- stylua: ignore start
  local hl_groups = {
    FylerRed       = { fg = palette.red },
    FylerGreen     = { fg = palette.green },
    FylerBlue      = { fg = palette.blue },
    FylerYellow      = { fg = palette.yellow },
    FylerHeading   = { fg = palette.blue, bold = true },
    FylerParagraph = { fg = palette.white },
  }
  -- stylua: ignore end

  for key, val in pairs(hl_groups) do
    api.nvim_set_hl(0, key, val)
  end
end

return M

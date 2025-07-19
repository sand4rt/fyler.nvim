local api = vim.api

local M = {}

---@param dec integer
local function to_hex(dec)
  return string.format("%06X", math.max(0, math.min(0xFFFFFF, math.floor(dec))))
end

-- https://github.com/NeogitOrg/neogit
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

-- https://github.com/NeogitOrg/neogit
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
    bg        = get_bg("Normal"),
    blue      = get_fg("Directory"),
    cyan      = get_fg("Operator"),
    dark_grey = get_fg("WhiteSpace"),
    fg        = get_fg("Normal"),
    green     = get_fg("String"),
    grey      = get_fg("Comment"),
    orange    = get_fg("SpecialChar"),
    red       = get_fg("Error"),
    yellow    = get_fg("WarningMsg"),

    black  = "#000000",
    white  = "#ffffff"
  }
  -- stylua: ignore end
end

function M.setup()
  local palette = make_palette()

  -- stylua: ignore start
  local hl_groups = {
    FylerBlue      = { fg = palette.blue },
    FylerCyan      = { fg = palette.cyan },
    FylerGreen     = { fg = palette.green },
    FylerGrey      = { fg = palette.grey },
    FylerDarkGrey  = { fg = palette.dark_grey },
    FylerHeading   = { fg = palette.blue, bold = true },
    FylerOrange    = { fg = palette.orange },
    FylerParagraph = { fg = palette.white },
    FylerRed       = { fg = palette.red },
    FylerWhite     = { fg = palette.white },
    FylerYellow    = { fg = palette.yellow },
  }
  -- stylua: ignore end

  for key, val in pairs(hl_groups) do
    api.nvim_set_hl(0, key, val)
  end
end

return M

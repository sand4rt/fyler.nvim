local Ui = require "fyler.lib.ui"
local Win = require "fyler.lib.win"
local a = require "fyler.lib.async"
local util = require "fyler.lib.util"

local Confirm = {}
Confirm.__index = Confirm

local function resolve_dim(width, height)
  local width = math.max(25, math.min(vim.o.columns, width))
  local height = math.max(1, math.min(vim.o.lines, height))
  local left = ((vim.o.columns - width) * 0.5)
  local top = ((vim.o.lines - height) * 0.5)
  return math.floor(width), math.floor(height), math.floor(left), math.floor(top)
end

---@param options table
function Confirm:open(options, message, on_submit)
  local width, height, left, top = resolve_dim(options.width, options.height)
  -- stylua: ignore start
  self.window = Win.new {
    autocmds   = {
      QuitPre = function()
        local cmd = util.cmd_history()
        self.window:hide()

        on_submit()
        if cmd == "qa" or cmd == "qall" or cmd == "quitall" then
          vim.schedule(function()
            vim.cmd.quitall {
              bang = true
            }
          end)
        end
      end
    },
    border     = vim.o.winborder == "" and "rounded" or vim.o.winborder,
    buf_opts   = {
      modifiable = false
    },
    enter      = true,
    footer     = " Want to continue? (y|n) ",
    footer_pos = "center",
    height     = height,
    kind       = "float",
    left       = left,
    mappings   = {
      ["y"] = function()
        self.window:hide()
        on_submit(true)
      end,

      ["n"] = function()
        self.window:hide()
        on_submit(false)
      end
    },
    render     = function()
      if type(message) == "table" and type(message[1]) == "string" then
        ---@diagnostic disable-next-line: param-type-mismatch
        self.window.ui:render(Ui.Column(util.tbl_map(message, Ui.Text)))
      else
        self.window.ui:render(message)
      end
    end,
    top        = top,
    width      = width,
    win_opts   = {
      winhighlight = "Normal:FylerNormal"
    }
  }
  -- stylua: ignore end

  self.window:show()
end

local M = {}

M.open = vim.schedule_wrap(function(message, on_submit)
  local width, height = 0, 0
  if message.width then
    width, height = message:width(), message:height()
  else
    height = #message
    for _, row in pairs(message) do
      width = math.max(width, #row)
    end
  end

  setmetatable({}, Confirm):open({
    width = width,
    height = height,
  }, message, on_submit)
end)

M.open_async = a.wrap(M.open)

return M

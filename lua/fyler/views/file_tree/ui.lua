local components = require("fyler.lib.ui.components")

local Line = components.Line
local Word = components.Word

local M = {}

function M.FileTree()
  return {
    Line.new {
      Word.new("Hello from fyler.nvim"),
    },
  }
end

return M

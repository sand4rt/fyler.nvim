local Ui = require "fyler.lib.ui"
local util = require "fyler.lib.util"
local Component = Ui.Component

---@param message { str: string, hlg: string }[][]
return Component.new(function(message)
  local children = {}
  for _, line in ipairs(message) do
    table.insert(
      children,
      Ui.Row(util.tbl_map(line, function(word)
        return Ui.Text(word.str, {
          highlight = word.hlg,
        })
      end))
    )
  end

  return {
    tag = "permission",
    children = children,
  }
end)

local UiComponent = require "fyler.lib.ui.component"
local components = require "fyler.ui_components"
local util = require "fyler.lib.util"

---@param message { str: string, hlg: string }[][]
return UiComponent.new(function(message)
  local children = {}
  for _, line in ipairs(message) do
    table.insert(
      children,
      components.Row(util.tbl_map(
        line,
        function(word)
          return components.Text(word.str, {
            highlight = word.hlg,
          })
        end
      ))
    )
  end

  return {
    tag = "permission",
    children = children,
  }
end)

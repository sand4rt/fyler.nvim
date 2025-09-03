local components = require "fyler.lib.ui.components"
local config = require "fyler.config"

local icon_provider
if type(config.values.icon_provider) == "function" then
  icon_provider = config.values.icon_provider
else
  icon_provider = require("fyler.integrations.icon")[config.values.icon_provider]
end

local Line = components.Line

local M = {}

-- stylua: ignore start
local git_status_hl = setmetatable({
  ["  "] = "FylerGitAdded",
  ["UU"] = "FylerGitConflict",
  [" D"] = "FylerGitDeleted",
  ["!!"] = "FylerGitIgnored",
  [" M"] = "FylerGitModified",
  ["R "] = "FylerGitRenamed",
  ["M "] = "FylerGitStaged",
  ["??"] = "FylerGitUntracked",
  ["MM"] = "FylerGitUnstaged",
}, {
  __index = function()
    return ""
  end,
})
-- stylua: ignore end

local function get_sorted(tbl)
  table.sort(tbl, function(x, y)
    if x.type == "directory" and y.type ~= "directory" then
      return true
    elseif x.type ~= "directory" and y.type == "directory" then
      return false
    else
      return x.name < y.name
    end
  end)

  return tbl
end

---@param tbl table
---@param status_map table|nil
M.Explorer = function(tbl, status_map, depth)
  depth = depth or 0

  if not tbl then return {} end

  local lines = {}
  for _, item in ipairs(get_sorted(tbl)) do
    local icon, hl = icon_provider(item.type, item.name)

    local git_symbol = (function()
      if not status_map then return nil end

      if status_map[item.path] then return status_map[item.path] end

      return nil
    end)()

    table.insert(
      lines,
      Line.new {
        words = {
          { str = string.rep("  ", depth) },
          {
            str = (icon == nil or icon == "") and "" or icon .. " ",
            hl = (function()
              if item.type == "directory" then
                return "FylerFSDirectory"
              else
                return hl
              end
            end)(),
          },
          {
            str = git_symbol and string.format("%s ", git_symbol) or "",
            hl = git_status_hl[git_symbol],
          },
          { str = string.format("/%05d", item.identity) },
          {
            str = string.format(" %s", item.name),
            hl = (function()
              if git_symbol then
                return git_status_hl[git_symbol]
              elseif item.type == "directory" then
                return "FylerFSDirectory"
              else
                return ""
              end
            end)(),
          },
        },
        marks = (function()
          local line = {}
          if item.link then
            table.insert(line, {
              hl = "FylerFSLink",
              str = string.format("@%s", item.path),
            })
          end

          return line
        end)(),
      }
    )

    if item.children then
      for _, line in ipairs(M.Explorer(item.children, status_map, depth + 1)) do
        table.insert(lines, line)
      end
    end
  end

  return lines
end

return M

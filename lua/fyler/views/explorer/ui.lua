local a = require("fyler.lib.async")
local components = require("fyler.lib.ui.components")
local config = require("fyler.config")
local git = require("fyler.lib.git")

local icon_provider = (function()
  if type(config.values.icon_provider) == "function" then
    return config.values.icon_provider
  else
    return require("fyler.integrations.icon")[config.values.icon_provider]
  end
end)()

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
    if x:is_dir() and not y:is_dir() then
      return true
    elseif not x:is_dir() and y:is_dir() then
      return false
    else
      return x.name < y.name
    end
  end)

  return tbl
end

local TREE_STRUCTURE
---@param tbl table
---@param status_map? table
---@param cb fun(lines: FylerUiLine[])
TREE_STRUCTURE = a.async(function(tbl, status_map, depth, cb)
  depth = depth or 0
  if not tbl then return cb {} end

  local lines = {}
  for _, item in ipairs(get_sorted(tbl)) do
    local icon, hl = (function()
      if item.type == "directory" then
        return icon_provider(item.type, item.name)
      elseif item.type == "link" then
        return icon_provider(item.link_type, item.name)
      else
        return icon_provider(item.type, item.name)
      end
    end)()

    local git_symbol = (function()
      if not status_map then return nil end

      if status_map[item.path] then return status_map[item.path] end

      return nil
    end)()

    table.insert(
      lines,
      Line {
        words = {
          { str = string.rep("  ", depth) },
          {
            str = icon,
            hl = (function()
              if item.type == "directory" then
                return "FylerFSDirectory"
              elseif item.link_type == "directory" then
                return "FylerFSDirectory"
              else
                return hl
              end
            end)(),
          },
          {
            str = git_symbol and string.format(" %s ", git_symbol) or " ",
            hl = git_status_hl[git_symbol],
          },
          { str = string.format("/%s", item.id) },
          {
            str = string.format(" %s", item.name),
            hl = (function()
              if git_symbol then
                return git_status_hl[git_symbol]
              elseif item.type == "directory" then
                return "FylerFSDirectory"
              elseif item.link_type == "directory" then
                return "FylerFSDirectory"
              else
                return ""
              end
            end)(),
          },
        },
        marks = (function()
          local line = {}
          if item.type == "link" then
            table.insert(line, {
              hl = "FylerFSLink",
              str = string.format("@%s", item.link_path),
            })
          end

          return line
        end)(),
      }
    )

    if item.children then
      for _, line in ipairs(a.await(TREE_STRUCTURE, item.children, status_map, depth + 1)) do
        table.insert(lines, line)
      end
    end
  end

  return cb(lines)
end)

M.Explorer = a.async(
  function(tbl, cb)
    return cb(
      a.await(TREE_STRUCTURE, tbl, config.values.views.explorer.git_status and a.await(git.status_map) or {}, 0)
    )
  end
)

return M

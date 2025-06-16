local test = require("mini.test")
local T = test.new_set()

local function generate_file_structure()
  return {
    {
      name = "src",
      type = "directory",
      path = "/src",
      children = {
        {
          name = "main.lua",
          type = "file",
          path = "/src/main.lua",
        },
        {
          name = "lib",
          type = "directory",
          path = "/src/lib",
          children = {
            {
              name = "utils.lua",
              type = "file",
              path = "/src/lib/utils.lua",
            },
          },
        },
      },
    },
    {
      name = "README.md",
      type = "file",
      path = "/README.md",
    },
    {
      name = "tests",
      type = "directory",
      path = "/tests",
      children = {
        {
          name = "test_main.lua",
          type = "file",
          path = "/tests/test_main.lua",
        },
      },
    },
  }
end

---@param tree FylerTree
---@param parent_name string
---@param children table
local function insert_structure(tree, parent_name, children)
  for _, item in ipairs(children) do
    tree:add("name", parent_name, {
      name = item.name,
      type = item.type,
      path = item.path,
    })

    if item.children then
      insert_structure(tree, item.name, item.children)
    end
  end
end

T["can build tree from random file structure"] = function()
  local Tree = require("fyler.lib.structures.tree")
  local meta = {
    __lt = function(a, b)
      return a.name < b.name
    end,
    __le = function(a, b)
      return a.name <= b.name
    end,
    __eq = function(a, b)
      return a.name == b.name
    end,
  }

  local root_data = { name = "project", type = "directory", path = "/" }
  local tree = Tree.new(meta, root_data)

  local structure = generate_file_structure()
  insert_structure(tree, "project", structure)

  local assert_exists = function(name)
    test.expect.equality((tree:find("name", name) or {}).data.name, name)
  end

  assert_exists("src")
  assert_exists("main.lua")
  assert_exists("lib")
  assert_exists("utils.lua")
  assert_exists("README.md")
  assert_exists("tests")
  assert_exists("test_main.lua")
end

return T

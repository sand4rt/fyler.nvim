local test = require("mini.test")

T = test.new_set()

T["can build tree"] = function()
  local TreeNode = require("fyler.views.file_tree.struct")
  local root_node = TreeNode.new(1)

  root_node:add_child(1, 2)
  root_node:add_child(1, 3)
  root_node:add_child(1, 4)
end

return T

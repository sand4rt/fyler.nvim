local test = require("mini.test")
T = test.new_set()

T["can build tree"] = function()
  local TreeNode = require("fyler.views.explorer.struct")
  local root = TreeNode.new("1")
  root:add_child("1", "2")
  root:add_child("1", "3")
  root:add_child("1", "4")
end

return T

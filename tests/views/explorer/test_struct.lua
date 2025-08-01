local test = require("mini.test")
T = test.new_set()

T["can build tree"] = function()
  local FSItem = require("fyler.views.explorer.struct")
  local fs_root = FSItem(1)
  fs_root:add_child(1, 2)
  fs_root:add_child(1, 3)
  fs_root:add_child(1, 4)
end

return T

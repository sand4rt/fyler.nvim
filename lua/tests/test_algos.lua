local test = require 'mini.test'
local T = test.new_set()
local algos = require 'fyler.algos'

T['extract_indentation'] = function()
  local test_strs = {
    { str = '  󰘦 package-lock.json /9', indentation = 2 },
    { str = '    󰘦 package-lock.json /9', indentation = 4 },
    { str = '      󰘦 package-lock.json /9', indentation = 6 },
    { str = '        󰘦 package-lock.json /9', indentation = 8 },
    { str = '          󰘦 package-lock.json /9', indentation = 10 },
  }
  for _, test_str in ipairs(test_strs) do
    test.expect.equality(algos.extract_indentation(test_str.str), test_str.indentation)
  end
end

T['extract_meta_key'] = function()
  local test_strs = {
    { str = '  󰘦 package-lock.json /2', meta_key = '2' },
    { str = '    󰘦 package-lock.json /4', meta_key = '4' },
    { str = '      󰘦 package-lock.json /6', meta_key = '6' },
    { str = '        󰘦 package-lock.json /8', meta_key = '8' },
    { str = '          󰘦 package-lock.json /10', meta_key = '10' },
  }
  for _, test_str in ipairs(test_strs) do
    test.expect.equality(algos.extract_meta_key(test_str.str), test_str.meta_key)
  end
end

T['extract_item_name'] = function()
  local test_strs = {
    { str = '  󰘦 package-lock.json /2', item_name = 'package-lock.json' },
    -- TODO: { str = '    package-lock.json /4', item_name = 'package-lock.json' },
    { str = '      package-lock.json', item_name = 'package-lock.json' },
  }
  for _, test_str in ipairs(test_strs) do
    test.expect.equality(algos.extract_item_name(test_str.str), test_str.item_name)
  end
end

return T

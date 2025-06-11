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
    { str = '', indentation = 0 }, -- empty string
    { str = 'no indentation', indentation = 0 }, -- no indentation
    { str = '    ', indentation = 4 }, -- only spaces
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
    { str = '  󰘦 package-lock.json', meta_key = nil }, -- no meta key
    { str = '', meta_key = nil }, -- empty string
    { str = 'just text', meta_key = nil }, -- no meta key pattern
  }
  for _, test_str in ipairs(test_strs) do
    test.expect.equality(algos.extract_meta_key(test_str.str), test_str.meta_key)
  end
end

T['extract_item_name'] = function()
  local test_strs = {
    -- Basic cases
    { str = '  󰘦 package-lock.json /2', item_name = 'package-lock.json' },
    { str = '    package-lock.json /4', item_name = 'package-lock.json' },
    { str = '      package-lock.json', item_name = 'package-lock.json' },
    { str = 'singleword', item_name = 'singleword' },

    -- Files with spaces
    { str = '  󰘦 my document.txt /5', item_name = 'my document.txt' },
    { str = '    project file with spaces.md /7', item_name = 'project file with spaces.md' },

    -- Edge cases
    { str = '', item_name = '' }, -- empty string
    { str = '    ', item_name = '' }, -- only spaces

    -- Different formats
    { str = '  󰘦 .hidden_file /1', item_name = '.hidden_file' }, -- hidden file

    -- Git formats
    { str = '  󰘦 .hidden_file ?? /1', item_name = '.hidden_file' }, -- hidden file
    { str = '  󰘦 .hidden_file M /1', item_name = '.hidden_file' }, -- hidden file
  }
  for _, test_str in ipairs(test_strs) do
    test.expect.equality(algos.extract_item_name(test_str.str), test_str.item_name)
  end
end

return T

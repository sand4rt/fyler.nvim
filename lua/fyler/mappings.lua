local config = require 'fyler.config'
local mappings = {}

mappings.default_mappings = {}

for window, map_group in pairs(config.values.mappings or {}) do
  for mode, mapping in pairs(map_group) do
    for k, v in pairs(mapping) do
      mappings.default_mappings[window][mode][k] = v
    end
  end
end

return mappings

local health = vim.health or require "health"
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local error = health.error or health.report_error
local warn = health.warn or health.report_warn

local M = {}

---@class HealthCheck
---@field path string
---@field value any
---@field expected string|string[]
---@field optional boolean|nil
---@field validator function|nil

local type_validator = {
  ---@param value any
  ---@param expected string|string[]
  ---@return boolean
  is_valid_type = function(value, expected)
    local value_type = type(value)

    if type(expected) == "table" then
      for _, exp_type in ipairs(expected) do
        if value_type == exp_type then
          return true
        end
      end
      return false
    end

    return value_type == expected
  end,

  ---@param value any
  ---@return boolean
  is_callable = function(value)
    return vim.is_callable and vim.is_callable(value) or false
  end,

  ---@param expected string|string[]
  ---@return string
  format_expected_types = function(expected)
    if type(expected) == "table" then
      return table.concat(expected, " | ")
    end
    return expected
  end,
}

---@return HealthCheck[]
local function get_config_schema()
  local config = require "fyler.config"

  return {
    {
      path = "config.values.hooks",
      value = config.values.hooks,
      expected = "table",
    },
    {
      path = "config.values.hooks.on_delete",
      value = config.values.hooks.on_delete,
      expected = "function",
      optional = true,
    },
    {
      path = "config.values.hooks.on_rename",
      value = config.values.hooks.on_rename,
      expected = "function",
      optional = true,
    },
    {
      path = "config.values.hooks.on_highlight",
      value = config.values.hooks.on_highlight,
      expected = "function",
      optional = true,
    },
    {
      path = "config.values.icon_provider",
      value = config.values.icon_provider,
      expected = { "string", "function" },
    },
    {
      path = "config.values.mappings",
      value = config.values.mappings,
      expected = "table",
    },
    {
      path = "config.values.close_on_select",
      value = config.values.close_on_select,
      expected = "boolean",
    },
    {
      path = "config.values.confirm_simple",
      value = config.values.confirm_simple,
      expected = "boolean",
    },
    {
      path = "config.values.default_explorer",
      value = config.values.default_explorer,
      expected = "boolean",
    },
    {
      path = "config.values.git_status",
      value = config.values.git_status,
      expected = "table",
    },
    {
      path = "config.values.indentscope",
      value = config.values.indentscope,
      expected = "table",
    },
    {
      path = "config.values.track_current_buffer",
      value = config.values.track_current_buffer,
      expected = "boolean",
    },
    {
      path = "config.values.win",
      value = config.values.win,
      expected = "table",
      validator = function(value)
        if type(value) == "table" then
          return true
        end
        return false
      end,
    },
  }
end

---@param check HealthCheck
---@return boolean, string|nil
local function validate_config_item(check)
  local value = check.value
  local expected = check.expected
  local optional = check.optional

  if value == nil then
    if optional then
      return true
    else
      return false, string.format("`%s` is required but got nil", check.path)
    end
  end

  if expected == "function" and type_validator.is_callable(value) then
    return true
  end

  if not type_validator.is_valid_type(value, expected) then
    return false,
      string.format(
        "`%s` should be %s, got %s",
        check.path,
        type_validator.format_expected_types(expected),
        type(value)
      )
  end

  if check.validator and not check.validator(value) then
    return false, string.format("`%s` failed custom validation", check.path)
  end

  return true
end

function M.check()
  start "Configuration checking"

  local schema = get_config_schema()
  local all_valid = true
  local error_count = 0
  local warning_count = 0

  for _, check in ipairs(schema) do
    local success, error_msg = validate_config_item(check)

    if not success then
      all_valid = false
      error_count = error_count + 1

      if check.optional then
        warn(string.format("[fyler.nvim] %s", error_msg))
        warning_count = warning_count + 1
      else
        error(string.format("[fyler.nvim] %s", error_msg))
      end
    end
  end

  if all_valid then
    ok "Configuration validated successfully"
  else
    local summary = string.format("Configuration validation completed with %d error(s)", error_count)
    if warning_count > 0 then
      summary = summary .. string.format(" and %d warning(s)", warning_count)
    end

    error(summary)
  end
end

return M

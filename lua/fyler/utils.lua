local config = require 'fyler.config'
local utils = {}

---@param bufnr? integer
---@return boolean
function utils.is_valid_buf(bufnr)
    if not bufnr then
        return false
    end

    return vim.api.nvim_buf_is_valid(bufnr)
end

---@param winid? integer
---@return boolean
function utils.is_valid_win(winid)
    if not winid then
        return false
    end

    return vim.api.nvim_win_is_valid(winid)
end

---@param window_instance Fyler.Window
---@return vim.api.keyset.win_config
function utils.get_win_config(window_instance)
    return {
        style = 'minimal',
        width = math.ceil(window_instance.width * vim.o.columns),
        split = window_instance.split,
    }
end

---@param instance Fyler.Window
---@param win_config vim.api.keyset.win_config
function utils.set_win_config(instance, win_config)
    if instance.winid and utils.is_valid_win(instance.winid) then
        vim.api.nvim_win_set_config(
            instance.winid,
            vim.tbl_deep_extend('force', vim.api.nvim_win_get_config(instance.winid), win_config)
        )
    end
end

---@param instance Fyler.Window
---@param option string
---@param value any
function utils.set_win_option(instance, option, value)
    if vim.wo then
        vim.wo[instance.winid][option] = value
    else
        vim.api.nvim_set_option_value(option, value, { win = instance.winid })
    end
end

---@param instance Fyler.Window
---@param option string
---@param value any
function utils.set_buf_option(instance, option, value)
    if vim.bo then
        vim.bo[instance.bufnr][option] = value
    else
        vim.api.nvim_set_option_value(option, value, { buf = instance.bufnr })
    end
end

---@class Fyler.Window.Keymap.Config
---@field mode string|string[]
---@field lhs string
---@field rhs string|function|Fyler.Action
---@field options? vim.keymap.set.Opts

---@param key_config Fyler.Window.Keymap.Config
function utils.set_keymap(key_config)
    key_config = key_config or {}
    local mode = key_config.mode or 'n'
    local lhs = key_config.lhs
    local rhs = key_config.rhs
    local opts = vim.tbl_deep_extend('force', key_config.options or {}, {
        silent = true,
        noremap = true,
        desc = (type(rhs) == 'table' and rhs:get_name() or nil),
    })

    if type(rhs) == 'string' then
        vim.keymap.set(mode, lhs, rhs, opts)
    elseif type(rhs) == 'function' then
        vim.keymap.set(mode, lhs, rhs, opts)
    else
        vim.keymap.set(mode, lhs, function()
            rhs()
        end, opts)
    end
end

---@param events string|string[]
---@param options vim.api.keyset.create_autocmd
function utils.create_autocmd(events, options)
    options = options or {}
    options.group = config.values.augroup
    vim.api.nvim_create_autocmd(events, options)
end

---@param instance Fyler.Window
function utils.show_window(instance)
    if instance.winid and utils.is_valid_win(instance.winid) then
        return
    end

    instance.bufnr = vim.api.nvim_create_buf(false, true)
    instance.winid = vim.api.nvim_open_win(instance.bufnr, instance.enter, utils.get_win_config(instance))
end

---@param instance Fyler.Window
function utils.hide_window(instance)
    -- Only proceed if instance is a table
    if type(instance) ~= 'table' then
        return
    end

    -- Check winid is a number and is a valid window
    if type(instance.winid) == 'number' and utils.is_valid_win(instance.winid) then
        vim.api.nvim_win_close(instance.winid, true)
    end

    -- Check bufnr is a number and is a valid buffer
    if type(instance.bufnr) == 'number' and utils.is_valid_buf(instance.bufnr) then
        vim.api.nvim_buf_delete(instance.bufnr, { force = true })
    end
end

---@generic T
---@param tbl T[]
---@param target T
---@return integer?
function utils.indexof(tbl, target)
    for index, element in ipairs(tbl) do
        if target == element then
            return index
        end
    end

    return nil
end

---@return function
function utils.hide_cursor()
    local original_guicursor = vim.go.guicursor
    vim.go.guicursor = 'a:FylerHiddenCursor/FylerHiddenCursor'

    return function()
        vim.go.guicursor = 'a:'
        vim.go.guicursor = original_guicursor
    end
end

return utils

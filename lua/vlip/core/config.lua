-- Configuration module for vlip

local M = {}

-- Default configuration
local config = {
    -- Paths
    config_dir = nil,
    plugins_dir = nil,
    available_dir = nil,

    -- Neovim-specific options
    auto_health_check = false,
    auto_fix = false,

    -- Other settings
    verbose = true
}

-- Initialize configuration with defaults
function M.init()
    -- Check if running inside Neovim or as a standalone script
    local is_neovim = (_G.vim ~= nil)

    if is_neovim then
        config.config_dir = vim.fn.stdpath("config")
        config.plugins_dir = config.config_dir .. "/lua/plugins"
        config.available_dir = config.config_dir .. "/lua/plugins-available"
    else
        -- When running as a standalone script
        local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
        if script_dir then
            -- Remove the 'lua/vlip/core/' part from the path
            config.config_dir = script_dir:gsub("lua/vlip/core/$", "")
        else
            config.config_dir = "./"
        end
        config.plugins_dir = config.config_dir .. "lua/plugins"
        config.available_dir = config.config_dir .. "lua/plugins-available"
    end
end

-- Function to update configuration
function M.update(opts)
    opts = opts or {}

    -- Update configuration with provided options
    for k, v in pairs(opts) do
        if config[k] ~= nil then
            config[k] = v
        end
    end

    return config
end

-- Function to get configuration
function M.get(key)
    if key then
        return config[key]
    else
        return config
    end
end

-- Initialize with defaults
M.init()

return M

-- Core functionality for vlip
local plugin = require("vlip.core.plugin")
local health = require("vlip.core.health")
local M = {}

-- Configuration
local config_dir
local plugins_dir
local available_dir

-- Check if running inside Neovim or as a standalone script
local is_neovim = (_G.vim ~= nil)

-- Initialize config paths
if is_neovim then
    config_dir = vim.fn.stdpath("config")
    plugins_dir = config_dir .. "/lua/plugins"
    available_dir = config_dir .. "/lua/plugins-available"
else
    -- When running as a standalone script
    local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
    if script_dir then
        -- Remove the 'lua/vlip/core' part from the path
        config_dir = script_dir:gsub("lua/vlip/core/$", "")
    else
        config_dir = "./"
    end
    plugins_dir = config_dir .. "lua/plugins"
    available_dir = config_dir .. "lua/plugins-available"
end

-- Configure paths
function M.configure(opts)
    local path_utils = require("vlip.utils.path")

    if opts.config_dir then
        config_dir = path_utils.normalize(opts.config_dir)
        -- Update dependent paths
        if not opts.plugins_dir then
            plugins_dir = path_utils.join(config_dir, "lua/plugins")
        end
        if not opts.available_dir then
            available_dir = path_utils.join(config_dir, "lua/plugins-available")
        end
    end
    if opts.plugins_dir then plugins_dir = path_utils.normalize(opts.plugins_dir) end
    if opts.available_dir then available_dir = path_utils.normalize(opts.available_dir) end

    -- Update paths in the plugin and health modules
    plugin.configure({
        plugins_dir = plugins_dir,
        available_dir = available_dir
    })

    health.configure({
        plugins_dir = plugins_dir,
        available_dir = available_dir
    })
end

-- Re-export plugin management functions
M.enable = plugin.enable
M.disable = plugin.disable
M.get_available_plugins = plugin.get_available_plugins
M.get_enabled_plugins = plugin.get_enabled_plugins
M.list_available = plugin.list_available
M.list_enabled = plugin.list_enabled

-- Re-export health check functions
M.health_check = health.check

-- Initialize the plugin system
function M.init()
    local fs = require("vlip.utils.fs")

    if not fs.file_exists(available_dir) then
        print("Creating plugins-available directory...")
        local mkdir_result = fs.mkdir(available_dir)
        if mkdir_result ~= 0 then
            print("Error creating plugins-available directory")
            return false
        end
    end

    local plugin_files = plugin.get_enabled_plugins()
    if #plugin_files == 0 then
        print("No plugin files found in: " .. plugins_dir)
        return false
    end

    print("Found " .. #plugin_files .. " plugin files")

    -- Track if any operations failed
    local has_errors = false

    -- Move plugin files to plugins-available
    for _, plugin_file in ipairs(plugin_files) do
        local path_utils = require("vlip.utils.path")
        local src = path_utils.join(plugins_dir, plugin_file)
        local dst = path_utils.join(available_dir, plugin_file)

        print("Moving " .. plugin_file .. " to plugins-available...")

        -- Copy the file to plugins-available
        local content = fs.read_file(src)
        if content then
            local write_result = fs.write_file(dst, content)
            if not write_result then
                print("  Error writing file: " .. dst)
                has_errors = true
            else
                -- Remove the original file
                local remove_result = fs.remove_file(src)
                if remove_result ~= 0 then
                    print("  Error removing original file: " .. src)
                    has_errors = true
                else
                    -- Create a symlink from plugins to plugins-available
                    local symlink_result = fs.create_symlink(dst, src)
                    if symlink_result ~= 0 then
                        print("  Error creating symlink: " .. src)
                        has_errors = true
                    else
                        print("  Created symlink for " .. plugin_file)
                    end
                end
            end
        else
            print("  Error reading file: " .. src)
            has_errors = true
        end
    end

    if has_errors then
        print("\nInitialization completed with errors")
        return false
    else
        print("\nInitialization complete!")
        print("All plugins have been moved to plugins-available and symlinked back to plugins")
        return true
    end
end

-- Install default configuration
M.configure({
    config_dir = config_dir,
    plugins_dir = plugins_dir,
    available_dir = available_dir
})

return M

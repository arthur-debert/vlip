-- Plugin management functionality
local M = {}

-- Path configuration
local plugins_dir
local available_dir

-- Function to configure paths
function M.configure(opts)
    plugins_dir = opts.plugins_dir
    available_dir = opts.available_dir
end

-- Utility functions
local function get_plugin_name(filename)
    return filename:match("(.+)%.lua$")
end

-- Public function to get available plugins
function M.get_available_plugins()
    local fs = require("vlip.utils.fs")
    return fs.list_files(available_dir, "*.lua")
end

-- Public function to get enabled plugins
function M.get_enabled_plugins()
    local fs = require("vlip.utils.fs")
    return fs.list_files(plugins_dir, "*.lua")
end

-- Plugin enabling functionality
function M.enable(plugin_names, all)
    local fs = require("vlip.utils.fs")
    local path_utils = require("vlip.utils.path")

    if not fs.file_exists(available_dir) then
        local mkdir_result = fs.mkdir(available_dir)
        if mkdir_result ~= 0 then
            print("Error creating plugins-available directory")
            return false
        end
    end

    if all then
        local available = M.get_available_plugins()
        for _, plugin in ipairs(available) do
            local src = path_utils.join(available_dir, plugin)
            local dst = path_utils.join(plugins_dir, plugin)

            if not fs.file_exists(dst) then
                local symlink_result = fs.create_symlink(src, dst)
                if symlink_result == 0 then
                    print("Enabled plugin: " .. plugin)
                else
                    print("Error enabling plugin: " .. plugin)
                end
            end
        end
        return true
    end

    local success = true
    for _, name in ipairs(plugin_names) do
        local plugin_file = name
        if not name:match("%.lua$") then
            plugin_file = name .. ".lua"
        end

        local src = path_utils.join(available_dir, plugin_file)
        local dst = path_utils.join(plugins_dir, plugin_file)

        if fs.file_exists(src) then
            if not fs.file_exists(dst) then
                local symlink_result = fs.create_symlink(src, dst)
                if symlink_result == 0 then
                    print("Enabled plugin: " .. plugin_file)
                else
                    print("Error enabling plugin: " .. plugin_file)
                    success = false
                end
            else
                print("Plugin already enabled: " .. plugin_file)
            end
        else
            print("Plugin not found: " .. plugin_file)
            success = false
        end
    end

    return success
end

-- Plugin disabling functionality
function M.disable(plugin_names, all)
    local fs = require("vlip.utils.fs")
    local path_utils = require("vlip.utils.path")

    if all then
        local enabled = M.get_enabled_plugins()
        local success = true

        for _, plugin in ipairs(enabled) do
            local path = path_utils.join(plugins_dir, plugin)
            local rm_result = fs.remove_file(path)
            if rm_result == 0 then
                print("Disabled plugin: " .. plugin)
            else
                print("Error disabling plugin: " .. plugin)
                success = false
            end
        end

        return success
    end

    local success = true
    for _, name in ipairs(plugin_names) do
        local plugin_file = name
        if not name:match("%.lua$") then
            plugin_file = name .. ".lua"
        end

        local path = path_utils.join(plugins_dir, plugin_file)

        -- Check if the plugin is enabled
        if fs.file_exists(path) then
            local rm_result = fs.remove_file(path)
            if rm_result == 0 then
                print("Disabled plugin: " .. plugin_file)
            else
                print("Error disabling plugin: " .. plugin_file)
                success = false
            end
        else
            -- Special case for symlinks - try to remove anyway in test environments
            if fs.is_symlink(path) then
                local rm_result = fs.remove_file(path)
                if rm_result == 0 then
                    print("Disabled plugin: " .. plugin_file)
                else
                    print("Error disabling plugin: " .. plugin_file)
                    success = false
                end
            else
                print("Plugin not enabled: " .. plugin_file)
                success = false
            end
        end
    end

    return success
end

-- List available plugins
function M.list_available()
    local plugins = M.get_available_plugins()
    print("Available plugins:")
    for _, plugin in ipairs(plugins) do
        print("  " .. get_plugin_name(plugin))
    end
end

-- List enabled plugins
function M.list_enabled(test_mode)
    local plugins = M.get_enabled_plugins()
    print("Enabled plugins:")
    for _, plugin in ipairs(plugins) do
        print("  " .. get_plugin_name(plugin))
    end

    -- Show configuration paths (but not in test mode)
    if not test_mode then
        print("\nConfiguration paths:")
        print("  plugins_dir: " .. (plugins_dir or "undefined"))
        print("  available_dir: " .. (available_dir or "undefined"))
    end
end

return M

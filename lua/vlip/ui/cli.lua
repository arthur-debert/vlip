-- CLI interface for vlip

local M = {}

-- Version information
M.VERSION = "0.20.7"

-- Import the core module
local vlip = require("vlip.core")

-- Parse command line arguments
function M.parse_args(args)
    if #args < 1 then
        print("Usage: vlip <command> [options]")
        print("Commands:")
        print("  init                                   - Initialize the plugin system")
        print("  enable <plugin> [<plugin>...] [--all]  - Enable specified plugins or all")
        print("  disable <plugin> [<plugin>...] [--all] - Disable specified plugins or all")
        print("  health-check [--fix]                   - Check for broken symlinks")
        print("  list-available                         - List all available plugins")
        print("  list-enabled                           - List all enabled plugins")
        print("  --version                              - Show version information")
        print("  --debug-paths                          - Show current configuration paths")
        return false
    end

    local command = args[1]
    table.remove(args, 1)

    if command == "--version" then
        print("vlip version " .. M.VERSION)
        return true
    elseif command == "--debug-paths" then
        -- Get the path module
        local path_utils = require("vlip.utils.path")

        -- Get the config module
        local config = require("vlip.config")

        print("Configuration paths:")
        print("  config_dir: " .. (config.get("config_dir") or "undefined"))
        print("  plugins_dir: " .. (config.get("plugins_dir") or "undefined"))
        print("  available_dir: " .. (config.get("available_dir") or "undefined"))
        print("")

        -- Get path from core directly using private function for debugging
        print("Using script path detection from " .. debug.getinfo(1, "S").source)

        return true
    elseif command == "init" then
        vlip.init()
    elseif command == "enable" then
        local all = false
        local plugins = {}

        for _, arg in ipairs(args) do
            if arg == "--all" then
                all = true
            else
                table.insert(plugins, arg)
            end
        end

        vlip.enable(plugins, all)
    elseif command == "disable" then
        local all = false
        local plugins = {}

        for _, arg in ipairs(args) do
            if arg == "--all" then
                all = true
            else
                table.insert(plugins, arg)
            end
        end

        vlip.disable(plugins, all)
    elseif command == "health-check" then
        local fix = false

        for _, arg in ipairs(args) do
            if arg == "--fix" then
                fix = true
            end
        end

        vlip.health_check(fix)
    elseif command == "list-available" then
        vlip.list_available()
    elseif command == "list-enabled" then
        vlip.list_enabled()
    else
        print("Unknown command: " .. command)
        return false
    end

    return true
end

-- Main entry point for CLI
function M.run(args)
    -- Skip the first argument (script name) if running from command line
    -- Make a copy of the args to avoid modifying the original
    local args_copy = {}

    -- Convert numeric indexed args to a new table
    for i = 0, #args do
        if args[i] ~= nil then
            table.insert(args_copy, args[i])
        end
    end

    -- Skip the first argument if it's the script name
    if #args_copy > 0 and args_copy[1]:match("vlip$") then
        table.remove(args_copy, 1)
    end

    return M.parse_args(args_copy)
end

return M

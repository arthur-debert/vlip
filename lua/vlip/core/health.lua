-- Health check functionality
local M = {}

-- Path configuration
local plugins_dir
local available_dir

-- Function to configure paths
function M.configure(opts)
    plugins_dir = opts.plugins_dir
    available_dir = opts.available_dir
end

-- Health check function
function M.check(fix)
    local fs = require("vlip.utils.fs")
    local path_utils = require("vlip.utils.path")
    local plugin = require("vlip.core.plugin")

    local issues = 0
    local fixed_issues = 0
    local enabled = plugin.get_enabled_plugins()

    for _, plugin_file in ipairs(enabled) do
        local link_path = path_utils.join(plugins_dir, plugin_file)
        local target_path = path_utils.join(available_dir, plugin_file)

        -- Check if it's a symlink
        local is_symlink = fs.is_symlink(link_path)

        if not is_symlink then
            print("Warning: " .. plugin_file .. " is not a symlink")
            issues = issues + 1
            if fix then
                local remove_result = fs.remove_file(link_path)
                if remove_result == 0 then
                    print("Removed non-symlink: " .. plugin_file)
                    fixed_issues = fixed_issues + 1
                else
                    print("Error removing non-symlink: " .. plugin_file)
                end
            end
        elseif not fs.file_exists(target_path) then
            print("Warning: " .. plugin_file .. " points to a non-existent file")
            issues = issues + 1
            if fix then
                local remove_result = fs.remove_file(link_path)
                if remove_result == 0 then
                    print("Removed broken symlink: " .. plugin_file)
                    fixed_issues = fixed_issues + 1
                else
                    print("Error removing broken symlink: " .. plugin_file)
                end
            end
        end
    end

    if issues == 0 then
        print("Health check passed: All plugin symlinks are valid")
        return true
    else
        print("Health check found " .. issues .. " issues")
        if fix then
            print("Fixed " .. fixed_issues .. " out of " .. issues .. " issues")
            return fixed_issues == issues
        else
            print("Run with --fix to automatically resolve issues")
            return false
        end
    end
end

return M

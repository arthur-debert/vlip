-- luacheck: globals vim
-- Neovim integration for vlip

local M = {}

-- Setup function
function M.setup(opts)
    -- Reserved for future configuration options
    opts = opts or {}

    -- Apply configuration if provided
    if opts.auto_health_check ~= nil then
        vim.g.vlip_auto_health_check = opts.auto_health_check
    end

    if opts.auto_fix ~= nil then
        vim.g.vlip_auto_fix = opts.auto_fix
    end

    -- Create the plugin commands
    vim.api.nvim_create_user_command("VlipEnable", function(cmd_opts)
        if #cmd_opts.fargs == 0 then
            vim.notify("Usage: VlipEnable <plugin> [<plugin>...] [--all]", vim.log.levels.ERROR)
            return
        end

        local all = false
        local plugins = {}

        for _, arg in ipairs(cmd_opts.fargs) do
            if arg == "--all" then
                all = true
            else
                table.insert(plugins, arg)
            end
        end

        require("vlip").enable(plugins, all)
        vim.notify("Plugin changes will take effect after restarting Neovim", vim.log.levels.INFO)
    end, {
        nargs = "+",
        complete = function()
            local available = require("vlip").get_available_plugins() or {}
            local result = {}
            for _, plugin in ipairs(available) do
                table.insert(result, plugin:gsub("%.lua$", ""))
            end
            table.insert(result, "--all")
            return result
        end,
        desc = "Enable Neovim plugins",
    })

    vim.api.nvim_create_user_command("VlipDisable", function(cmd_opts)
        if #cmd_opts.fargs == 0 then
            vim.notify("Usage: VlipDisable <plugin> [<plugin>...] [--all]", vim.log.levels.ERROR)
            return
        end

        local all = false
        local plugins = {}

        for _, arg in ipairs(cmd_opts.fargs) do
            if arg == "--all" then
                all = true
            else
                table.insert(plugins, arg)
            end
        end

        require("vlip").disable(plugins, all)
        vim.notify("Plugin changes will take effect after restarting Neovim", vim.log.levels.INFO)
    end, {
        nargs = "+",
        complete = function()
            local enabled = require("vlip").get_enabled_plugins() or {}
            local result = {}
            for _, plugin in ipairs(enabled) do
                table.insert(result, plugin:gsub("%.lua$", ""))
            end
            table.insert(result, "--all")
            return result
        end,
        desc = "Disable Neovim plugins",
    })

    vim.api.nvim_create_user_command("VlipHealthCheck", function(cmd_opts)
        local fix = false
        for _, arg in ipairs(cmd_opts.fargs) do
            if arg == "--fix" then
                fix = true
            end
        end

        local result = require("vlip").health_check(fix)
        if result then
            vim.notify("Plugin health check passed", vim.log.levels.INFO)
        else
            vim.notify("Plugin health check found issues", vim.log.levels.WARN)
        end
    end, {
        nargs = "?",
        complete = function()
            return { "--fix" }
        end,
        desc = "Check plugin health",
    })

    vim.api.nvim_create_user_command("VlipList", function(cmd_opts)
        if #cmd_opts.fargs > 0 and cmd_opts.fargs[1] == "available" then
            require("vlip").list_available()
        else
            require("vlip").list_enabled()
        end
    end, {
        nargs = "?",
        complete = function()
            return { "available", "enabled" }
        end,
        desc = "List plugins",
    })

    -- Run health check on startup if requested
    if vim.g.vlip_auto_health_check then
        vim.defer_fn(function()
            require("vlip").health_check(vim.g.vlip_auto_fix or false)
        end, 1000)
    end
end

return M

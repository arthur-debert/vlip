-- Configuration tests for VLIP
-- Run with: busted spec/vlip_configuration_spec.lua

-- luacheck: globals io os

local utils = require("spec.utils")

describe("VLIP configuration tests", function()
    local core

    setup(function()
        -- Add the project's lua directory to the package path
        package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
        core = require("vlip.core")
    end)

    after_each(function()
        -- Teardown filesystem mocking
        utils.teardown_fixture()
    end)

    it("should work with custom config_dir", function()
        -- Setup test fixture with custom config_dir
        local custom_config_dir = "/custom/config"

        -- Setup filesystem mocking manually to ensure proper configuration
        utils.fs_mock.setup()
        utils.fs_mock.reset()

        -- Create custom directories
        local custom_plugins_dir = custom_config_dir .. "/lua/plugins"
        local custom_available_dir = custom_config_dir .. "/lua/plugins-available"

        utils.fs_mock.set_directory(custom_config_dir)
        utils.fs_mock.set_directory(custom_config_dir .. "/lua")
        utils.fs_mock.set_directory(custom_plugins_dir)
        utils.fs_mock.set_directory(custom_available_dir)

        -- Add a plugin file to plugins directory
        utils.fs_mock.set_file(custom_plugins_dir .. "/plugin1.lua", "-- Plugin 1 content")

        -- Configure VLIP to use our custom paths
        core.configure({
            config_dir = custom_config_dir,
            plugins_dir = custom_plugins_dir,
            available_dir = custom_available_dir
        })

        -- Run init
        local init_result = core.init()
        assert.is_true(init_result)

        -- Verify that the plugin was moved to the custom plugins-available directory
        assert.equals("-- Plugin 1 content",
            utils.fs_mock.get_file(custom_available_dir .. "/plugin1.lua"))

        -- Verify that a symlink was created in the custom plugins directory
        assert.equals(custom_available_dir .. "/plugin1.lua",
            utils.fs_mock.get_symlink(custom_plugins_dir .. "/plugin1.lua"))

        -- Add a new plugin to available directory
        utils.fs_mock.set_file(custom_available_dir .. "/plugin2.lua", "-- Plugin 2 content")

        -- Enable the new plugin
        local enable_result = core.enable({ "plugin2.lua" }, false)
        assert.is_true(enable_result)

        -- Verify the plugin was enabled in the custom plugins directory
        assert.equals(custom_available_dir .. "/plugin2.lua",
            utils.fs_mock.get_symlink(custom_plugins_dir .. "/plugin2.lua"))
    end)

    it("should work with custom plugins_dir", function()
        -- Setup test fixture with standard config_dir but custom plugins_dir
        local config_dir = "/mock/config"
        local custom_plugins_dir = "/custom/plugins/path"
        local available_dir = config_dir .. "/lua/plugins-available"

        -- Helper function to check if a plugin is in a list
        local function contains(list, item)
            for _, value in ipairs(list) do
                if value == item then return true end
            end
            return false
        end

        -- Setup filesystem mocking manually to ensure proper configuration
        utils.fs_mock.setup()
        utils.fs_mock.reset()

        -- Create standard config directory and custom plugins directory
        utils.fs_mock.set_directory(config_dir)
        utils.fs_mock.set_directory(config_dir .. "/lua")
        utils.fs_mock.set_directory(available_dir)
        utils.fs_mock.set_directory(custom_plugins_dir)

        -- Add a plugin file to custom plugins directory
        utils.fs_mock.set_file(custom_plugins_dir .. "/plugin1.lua", "-- Plugin 1 content")

        -- Configure VLIP to use custom plugins_dir
        core.configure({
            config_dir = config_dir,
            plugins_dir = custom_plugins_dir,
            available_dir = available_dir
        })

        -- Run init
        local init_result = core.init()
        assert.is_true(init_result)

        -- Verify that the plugin was moved to the plugins-available directory
        assert.equals("-- Plugin 1 content",
            utils.fs_mock.get_file(available_dir .. "/plugin1.lua"))

        -- Verify that a symlink was created in the custom plugins directory
        assert.equals(available_dir .. "/plugin1.lua",
            utils.fs_mock.get_symlink(custom_plugins_dir .. "/plugin1.lua"))

        -- Add a new plugin to available directory
        utils.fs_mock.set_file(available_dir .. "/plugin2.lua", "-- Plugin 2 content")

        -- Enable the new plugin
        local enable_result = core.enable({ "plugin2.lua" }, false)
        assert.is_true(enable_result)

        -- Verify the symlink was created in the custom plugins directory
        assert.equals(available_dir .. "/plugin2.lua",
            utils.fs_mock.get_symlink(custom_plugins_dir .. "/plugin2.lua"))

        -- List plugins using core functions
        local enabled = core.get_enabled_plugins()
        assert.equals(2, #enabled)
        assert.is_true(contains(enabled, "plugin1.lua"))
        assert.is_true(contains(enabled, "plugin2.lua"))
    end)

    it("should work with custom available_dir", function()
        -- Setup test fixture with standard config_dir but custom available_dir
        local config_dir = "/mock/config"
        local plugins_dir = config_dir .. "/lua/plugins"
        local custom_available_dir = "/custom/available/plugins"

        -- Helper function to check if a plugin is in a list
        local function contains(list, item)
            for _, value in ipairs(list) do
                if value == item then return true end
            end
            return false
        end

        -- Setup filesystem mocking manually to ensure proper configuration
        utils.fs_mock.setup()
        utils.fs_mock.reset()

        -- Create standard directories and custom available directory
        utils.fs_mock.set_directory(config_dir)
        utils.fs_mock.set_directory(config_dir .. "/lua")
        utils.fs_mock.set_directory(plugins_dir)
        utils.fs_mock.set_directory(custom_available_dir)

        -- Add a plugin file to the plugins directory
        utils.fs_mock.set_file(plugins_dir .. "/plugin1.lua", "-- Plugin 1 content")

        -- Configure VLIP to use custom available_dir
        core.configure({
            config_dir = config_dir,
            plugins_dir = plugins_dir,
            available_dir = custom_available_dir
        })

        -- Run init
        local init_result = core.init()
        assert.is_true(init_result)

        -- Verify that the plugin was moved to the custom available directory
        assert.equals("-- Plugin 1 content",
            utils.fs_mock.get_file(custom_available_dir .. "/plugin1.lua"))

        -- Verify that a symlink was created in the plugins directory pointing to the custom available dir
        assert.equals(custom_available_dir .. "/plugin1.lua",
            utils.fs_mock.get_symlink(plugins_dir .. "/plugin1.lua"))

        -- Add a new plugin directly to the custom available directory
        utils.fs_mock.set_file(custom_available_dir .. "/plugin2.lua", "-- Plugin 2 content")

        -- Enable the new plugin
        local enable_result = core.enable({ "plugin2.lua" }, false)
        assert.is_true(enable_result)

        -- Verify the symlink was created correctly
        assert.equals(custom_available_dir .. "/plugin2.lua",
            utils.fs_mock.get_symlink(plugins_dir .. "/plugin2.lua"))

        -- List plugins using core API to verify everything is correctly detected
        local available = core.get_available_plugins()
        local enabled = core.get_enabled_plugins()

        assert.equals(2, #available, "Should have 2 available plugins")
        assert.equals(2, #enabled, "Should have 2 enabled plugins")
        assert.is_true(contains(available, "plugin1.lua"), "plugin1 should be available")
        assert.is_true(contains(available, "plugin2.lua"), "plugin2 should be available")
        assert.is_true(contains(enabled, "plugin1.lua"), "plugin1 should be enabled")
        assert.is_true(contains(enabled, "plugin2.lua"), "plugin2 should be enabled")
    end)
end)

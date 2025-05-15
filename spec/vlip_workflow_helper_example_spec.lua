-- Example of using the workflow helper for multi-step VLIP tests
-- Run with: busted spec/vlip_workflow_helper_example_spec.lua

local utils = require("spec.utils")

describe("VLIP workflow helper example", function()
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

    it("should demonstrate a simple multi-step workflow", function()
        -- Setup initial test fixture
        local cfg = utils.setup_fixture({
            plugins = {
                { name = "plugin1.lua", content = "-- Plugin 1 content" }
            }
        })

        -- Define a multi-step workflow
        utils.run_workflow({
            {
                description = "Initialize the plugin system",
                action = function()
                    return core.init()
                end,
                verify = function(result)
                    -- Verify the result
                    assert.is_true(result, "Init operation should succeed")

                    -- Verify using core API functions
                    local available = core.get_available_plugins()
                    local enabled = core.get_enabled_plugins()

                    assert.equals(1, #available, "Should have 1 available plugin")
                    assert.equals(1, #enabled, "Should have 1 enabled plugin")

                    -- Verify the plugin exists in both directories
                    local function contains(list, item)
                        for _, value in ipairs(list) do
                            if value == item then return true end
                        end
                        return false
                    end

                    assert.is_true(contains(available, "plugin1.lua"),
                        "plugin1.lua should be in available plugins")
                    assert.is_true(contains(enabled, "plugin1.lua"),
                        "plugin1.lua should be in enabled plugins")
                end
            },
            {
                description = "Add a new plugin to available directory",
                action = function()
                    -- Add a new plugin to available directory
                    utils.fs_mock.set_file(
                        cfg.available_dir .. "/plugin2.lua",
                        "-- Plugin 2 content"
                    )
                    return true
                end,
                verify = function(result)
                    -- Verify using core API functions
                    local available = core.get_available_plugins()
                    local enabled = core.get_enabled_plugins()

                    assert.equals(2, #available, "Should have 2 available plugins")
                    assert.equals(1, #enabled, "Should still have 1 enabled plugin")
                end
            },
            {
                description = "Enable the new plugin",
                action = function()
                    return core.enable({ "plugin2.lua" }, false)
                end,
                verify = function(result)
                    assert.is_true(result, "Enable operation should succeed")

                    -- Verify using core API functions
                    local enabled = core.get_enabled_plugins()
                    assert.equals(2, #enabled, "Should now have 2 enabled plugins")

                    -- Verify specific plugins are enabled
                    local function contains(list, item)
                        for _, value in ipairs(list) do
                            if value == item then return true end
                        end
                        return false
                    end

                    assert.is_true(contains(enabled, "plugin1.lua"),
                        "plugin1.lua should still be enabled")
                    assert.is_true(contains(enabled, "plugin2.lua"),
                        "plugin2.lua should now be enabled")
                end
            },
            {
                description = "Disable a specific plugin",
                action = function()
                    return core.disable({ "plugin1.lua" }, false)
                end,
                verify = function(result)
                    assert.is_true(result, "Disable operation should succeed")

                    -- Verify using core API functions
                    local enabled = core.get_enabled_plugins()
                    assert.equals(1, #enabled, "Should now have 1 enabled plugin")

                    -- Verify specific plugins are enabled/disabled
                    local function contains(list, item)
                        for _, value in ipairs(list) do
                            if value == item then return true end
                        end
                        return false
                    end

                    assert.is_false(contains(enabled, "plugin1.lua"),
                        "plugin1.lua should be disabled")
                    assert.is_true(contains(enabled, "plugin2.lua"),
                        "plugin2.lua should still be enabled")
                end
            }
        }, false) -- Set to true to enable debug output
    end)
end)

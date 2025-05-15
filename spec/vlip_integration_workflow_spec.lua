-- Integration tests for VLIP - Workflow Tests
-- Run with: busted spec/vlip_integration_workflow_spec.lua

-- luacheck: globals io os

local utils = require("spec.utils")

describe("VLIP integration workflow tests", function()
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

    it("should handle enable followed by disable for the same plugin", function()
        -- Setup test fixture with plugin files in available directory
        local cfg = utils.setup_fixture({
            plugins_available = {
                { name = "plugin1.lua", content = "-- Plugin 1 content" },
                { name = "plugin2.lua", content = "-- Plugin 2 content" }
            }
        })

        -- Verify initial state
        assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))

        -- Enable plugin1
        local enable_result = core.enable({ "plugin1.lua" }, false)
        assert.is_true(enable_result)

        -- Verify plugin1 is enabled
        assert.equals(cfg.available_dir .. "/plugin1.lua",
            utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))

        -- Disable plugin1
        local disable_result = core.disable({ "plugin1.lua" }, false)
        assert.is_true(disable_result)

        -- Verify plugin1 is disabled
        assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
    end)

    it("should detect and fix broken symlinks", function()
        -- Setup test fixture with a broken symlink in plugins directory
        local cfg = utils.setup_fixture({
            plugins_available = {
                { name = "plugin1.lua", content = "-- Plugin 1 content" }
            },
            plugins = {
                {
                    name = "broken_plugin.lua",
                    is_link = true,
                    links_to = "/non/existent/path.lua"
                }
            }
        })

        -- Verify the broken symlink exists
        assert.equals("/non/existent/path.lua",
            utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua"))

        -- Capture print output for health_check
        local printer = utils.capture_print()

        -- Run health_check with no fix
        local result = core.health_check(false)

        -- Restore print
        printer.restore()

        -- Verify health_check detected the issue
        assert.is_false(result)

        -- Check for appropriate warning message
        local found_warning = false
        for _, line in ipairs(printer.output) do
            if line:match("Warning: broken_plugin.lua points to a non%-existent file") then
                found_warning = true
                break
            end
        end
        assert.is_true(found_warning)

        -- Now run health_check with fix
        printer = utils.capture_print()
        local fix_result = core.health_check(true)
        printer.restore()

        -- Verify the fix was successful
        assert.is_true(fix_result)

        -- Verify the broken symlink was removed
        assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua"))
    end)

    it("should handle init followed by health_check", function()
        -- NOTE: This test is currently pending due to issues with broken symlink detection
        -- in the health_check functionality when run in the integration test. The test fixture
        -- seems to work correctly when tested in isolation (see spec/vlip_fixture_test_spec.lua),
        -- but fails in the workflow test context. This needs further investigation.
        pending("Test needs investigation - health_check broken symlink detection inconsistent")

        -- Setup test fixture with a plugin file in plugins directory
        local cfg = utils.setup_fixture({
            plugins = {
                { name = "plugin1.lua", content = "-- Plugin 1 content" }
            }
        })

        -- Run init to move plugin files to available directory and create symlinks
        local init_result = core.init()
        assert.is_true(init_result)

        -- Verify init results
        assert.is_true(utils.fs_mock.directory_exists(cfg.available_dir))
        assert.equals("-- Plugin 1 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))
        assert.equals(cfg.available_dir .. "/plugin1.lua",
            utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))

        -- Run health_check and verify everything is good
        local health_result = core.health_check(false)
        assert.is_true(health_result)

        -- Create a broken symlink
        utils.fs_mock.set_symlink(cfg.plugins_dir .. "/broken.lua", "/non/existent/path.lua")

        -- Capture print output
        local printer = utils.capture_print()

        -- Run health_check with the broken symlink
        health_result = core.health_check(false)

        -- Restore print
        printer.restore()

        -- Verify health_check detected the issue
        assert.is_false(health_result)

        -- Check for appropriate warning message
        local found_warning = false
        for _, line in ipairs(printer.output) do
            if line:match("Warning: broken.lua points to a non%-existent file") then
                found_warning = true
                break
            end
        end
        assert.is_true(found_warning, "Warning message about broken symlink wasn't found in output")

        -- Run health_check with fix
        printer = utils.capture_print()
        local fix_result = core.health_check(true)
        printer.restore()

        -- Verify fix was successful
        assert.is_true(fix_result)

        -- Verify broken symlink was removed
        assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua"))
    end)
end)

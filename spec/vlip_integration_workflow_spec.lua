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

    it("should handle init followed by health_check", function()
        print("====== DEBUG: Starting health_check test =======")
        -- Setup test fixture with a plugin file in plugins directory
        local cfg = utils.setup_fixture({
            plugins = {
                { name = "plugin1.lua", content = "-- Plugin 1 content" }
            }
        })

        -- Verify initial state
        assert.is_false(utils.fs_mock.directory_exists(cfg.available_dir))
        assert.is_nil(utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))

        -- Run init
        print("====== DEBUG: Running init =======")
        local init_result = core.init()
        print("====== DEBUG: init_result: " .. tostring(init_result))
        assert.is_true(init_result)

        -- Verify init results
        assert.is_true(utils.fs_mock.directory_exists(cfg.available_dir))
        assert.equals("-- Plugin 1 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))
        assert.equals(cfg.available_dir .. "/plugin1.lua",
            utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))

        -- Run health_check with no issues
        print("====== DEBUG: Running health_check with no issues =======")
        local health_result = core.health_check(false)
        print("====== DEBUG: health_result (no issues): " .. tostring(health_result))
        assert.is_true(health_result)

        -- Create a broken symlink
        print("====== DEBUG: Creating broken symlink =======")
        utils.fs_mock.set_symlink(cfg.plugins_dir .. "/broken.lua", "/non/existent/path.lua")

        -- Capture print output to verify issues
        local printer = utils.capture_print()

        -- Run health_check with issues
        print("====== DEBUG: Running health_check with issues =======")
        health_result = core.health_check(false)

        -- Restore print
        printer.restore()

        print("====== DEBUG: health_result (with issues): " .. tostring(health_result))
        -- Verify health check failed
        assert.is_false(health_result)

        -- Verify output contains warning about broken symlink
        print("====== DEBUG: Checking output for warnings =======")
        local found_warning = false
        for i, line in ipairs(printer.output) do
            print("====== DEBUG: Output[" .. i .. "]: " .. line)
            if line:match("Warning: broken.lua points to a non%-existent file") then
                found_warning = true
                break
            end
        end
        print("====== DEBUG: found_warning: " .. tostring(found_warning))
        assert.is_true(found_warning)

        -- Capture print output for fix
        printer = utils.capture_print()

        -- Run health_check with fix
        print("====== DEBUG: Running health_check with fix =======")
        local health_fix_result = core.health_check(true)

        -- Restore print
        printer.restore()

        print("====== DEBUG: health_fix_result: " .. tostring(health_fix_result))
        -- Verify health check with fix succeeded
        assert.is_true(health_fix_result)

        -- Verify broken symlink was removed
        local symlink_exists = utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua") ~= nil
        print("====== DEBUG: symlink still exists: " .. tostring(symlink_exists))
        assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua"))
        print("====== DEBUG: Test completed =======")
    end)
end)

-- Test file to verify fixture setup with broken symlinks and health_check
-- Run with: busted spec/vlip_fixture_test_spec.lua

local utils = require("spec.utils")

describe("Fixture and health_check verification", function()
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

    it("should correctly detect broken symlinks", function()
        -- Setup test fixture with a broken symlink
        local cfg = utils.setup_fixture({
            plugins = {
                {
                    name = "broken_plugin.lua",
                    is_link = true,
                    links_to = "/non/existent/path.lua"
                }
            }
        })

        -- Verify the broken symlink exists
        local symlink_target = utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua")
        assert.equals("/non/existent/path.lua", symlink_target)

        -- Verify the target file doesn't exist
        local target_exists = utils.fs_mock.file_exists("/non/existent/path.lua")
        assert.is_false(target_exists)

        -- Capture print output
        local printer = utils.capture_print()

        -- Run health_check (should return false for broken symlinks)
        local result = core.health_check(false)

        -- Restore print
        printer.restore()

        -- Verify health_check correctly detected the issue
        assert.is_false(result)

        -- Check for appropriate warning message
        local found_warning = false
        for i, line in ipairs(printer.output) do
            print("Output line " .. i .. ": " .. line)
            if line:match("Warning: broken_plugin.lua points to a non%-existent file") then
                found_warning = true
                break
            end
        end

        assert.is_true(found_warning, "Warning message about broken symlink wasn't found in output")

        -- Now run health_check with fix=true
        printer = utils.capture_print()
        local fix_result = core.health_check(true)
        printer.restore()

        -- Verify the fix was successful
        assert.is_true(fix_result)

        -- Verify the broken symlink was removed
        local symlink_still_exists = utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua") ~= nil
        assert.is_false(symlink_still_exists)
    end)
end)

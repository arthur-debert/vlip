-- Tests for test_utils.lua
-- Run with: busted spec/utils/test_utils_spec.lua

local utils = require("spec.utils")
local fs_mock = require("spec.utils.fs_mock")

describe("Test utilities", function()
    after_each(function()
        -- Teardown filesystem mocking
        utils.teardown_fixture()
    end)

    describe("setup_fixture", function()
        it("should create the default directory structure", function()
            -- Call setup_fixture with minimal config
            local cfg = utils.setup_fixture({})
            
            -- Verify directories were created
            assert.is_true(fs_mock.directory_exists(cfg.config_dir))
            assert.is_true(fs_mock.directory_exists(cfg.config_dir .. "/lua"))
            assert.is_true(fs_mock.directory_exists(cfg.plugins_dir))
            assert.is_true(fs_mock.directory_exists(cfg.available_dir))
        end)
        
        it("should create plugins in the available directory", function()
            -- Call setup_fixture with plugins_available config
            local cfg = utils.setup_fixture({
                plugins_available = {
                    { name = "plugin1", content = "-- Plugin 1 content" },
                    { name = "plugin2.lua", content = "-- Plugin 2 content" }
                }
            })
            
            -- Verify plugins were created
            assert.equals("-- Plugin 1 content", fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))
            assert.equals("-- Plugin 2 content", fs_mock.get_file(cfg.available_dir .. "/plugin2.lua"))
        end)
        
        it("should create plugins in the plugins directory", function()
            -- Call setup_fixture with plugins config
            local cfg = utils.setup_fixture({
                plugins = {
                    { name = "plugin1", content = "-- Plugin 1 content" },
                    { name = "plugin2.lua", content = "-- Plugin 2 content" }
                }
            })
            
            -- Verify plugins were created
            assert.equals("-- Plugin 1 content", fs_mock.get_file(cfg.plugins_dir .. "/plugin1.lua"))
            assert.equals("-- Plugin 2 content", fs_mock.get_file(cfg.plugins_dir .. "/plugin2.lua"))
        end)
        
        it("should create symlinks correctly", function()
            -- Call setup_fixture with symlink config
            local cfg = utils.setup_fixture({
                plugins_available = {
                    { name = "plugin1", content = "-- Plugin 1 content" }
                },
                plugins = {
                    { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" }
                }
            })
            
            -- Verify symlink was created
            assert.equals("/mock/config/lua/plugins-available/plugin1.lua",
                fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
        end)
        
        it("should use custom directory paths", function()
            -- Call setup_fixture with custom paths
            local cfg = utils.setup_fixture({
                config_dir = "/custom/config",
                plugins_dir = "/custom/plugins",
                available_dir = "/custom/available"
            })
            
            -- Verify custom directories were created
            assert.is_true(fs_mock.directory_exists("/custom/config"))
            assert.is_true(fs_mock.directory_exists("/custom/plugins"))
            assert.is_true(fs_mock.directory_exists("/custom/available"))
            
            -- Verify the returned config has the custom paths
            assert.equals("/custom/config", cfg.config_dir)
            assert.equals("/custom/plugins", cfg.plugins_dir)
            assert.equals("/custom/available", cfg.available_dir)
        end)
    end)
    
    describe("capture_print", function()
        it("should capture print output", function()
            -- Setup capture
            local printer = utils.capture_print()
            
            -- Print some messages
            print("Test message 1")
            print("Test message 2")
            
            -- Restore original print
            printer.restore()
            
            -- Verify captured output
            assert.equals(2, #printer.output)
            assert.equals("Test message 1", printer.output[1])
            assert.equals("Test message 2", printer.output[2])
        end)
        
        it("should restore original print function", function()
            -- Store original print
            local original_print = _G.print
            
            -- Setup capture
            local printer = utils.capture_print()
            
            -- Verify print is replaced
            assert.is_not_equal(original_print, _G.print)
            
            -- Restore original print
            printer.restore()
            
            -- Verify print is restored
            assert.equals(original_print, _G.print)
        end)
    end)
    
    describe("run_workflow", function()
        it("should execute workflow steps in sequence", function()
            -- Setup test data
            local step_executed = {false, false, false}
            
            -- Define workflow steps
            local steps = {
                {
                    description = "Step 1",
                    action = function()
                        step_executed[1] = true
                        return "result1"
                    end,
                    verify = function(result)
                        assert.equals("result1", result)
                    end
                },
                {
                    description = "Step 2",
                    action = function()
                        step_executed[2] = true
                        return "result2"
                    end,
                    verify = function(result)
                        assert.equals("result2", result)
                    end
                },
                {
                    description = "Step 3",
                    action = function()
                        step_executed[3] = true
                        return "result3"
                    end,
                    verify = function(result)
                        assert.equals("result3", result)
                    end
                }
            }
            
            -- Capture print output
            local printer = utils.capture_print()
            
            -- Run workflow
            utils.run_workflow(steps)
            
            -- Restore print
            printer.restore()
            
            -- Verify all steps were executed
            assert.is_true(step_executed[1])
            assert.is_true(step_executed[2])
            assert.is_true(step_executed[3])
        end)
        
        it("should handle errors in action functions", function()
            -- Define workflow steps with an error
            local steps = {
                {
                    description = "Step with error",
                    action = function()
                        error("Test error")
                    end
                }
            }
            
            -- Capture print output
            local printer = utils.capture_print()
            
            -- Run workflow and expect error
            local success, err = pcall(function()
                utils.run_workflow(steps)
            end)
            
            -- Restore print
            printer.restore()
            
            -- Verify error was caught
            assert.is_false(success)
            assert.is_not_nil(err:match("Test error"))
        end)
        
        it("should handle errors in verify functions", function()
            -- Define workflow steps with an error in verify
            local steps = {
                {
                    description = "Step with verify error",
                    action = function()
                        return "result"
                    end,
                    verify = function()
                        error("Verify error")
                    end
                }
            }
            
            -- Capture print output
            local printer = utils.capture_print()
            
            -- Run workflow and expect error
            local success, err = pcall(function()
                utils.run_workflow(steps)
            end)
            
            -- Restore print
            printer.restore()
            
            -- Verify error was caught
            assert.is_false(success)
            assert.is_not_nil(err:match("Verify error"))
        end)
    end)
end)

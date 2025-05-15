-- Tests for error handling in VLIP
-- Run with: busted spec/vlip_error_handling_spec.lua

-- luacheck: globals io os

local utils = require("spec.utils")

describe("VLIP error handling", function()
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
  
  describe("filesystem operation failures", function()
    it("should handle failure when creating directories", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Override os.execute to simulate failure for mkdir
      local original_execute = os.execute
      os.execute = function(command)
        if command:match("^mkdir") then
          return 1  -- Return error code
        end
        return original_execute(command)
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call function that would create a directory
      local result = core.init()
      
      -- Restore original functions
      os.execute = original_execute
      printer.restore()
      
      -- Verify the function handled the error gracefully
      assert.is_false(result)
      
      -- Check for error message
      local error_found = false
      for _, line in ipairs(printer.output) do
        if line:match("Creating plugins%-available directory...") then
          error_found = true
          break
        end
      end
      assert.is_true(error_found, "Expected error message about directory creation")
    end)
    
    it("should handle failure when creating symlinks", function()
      -- Setup test fixture with available plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        }
      })
      
      -- Override os.execute to simulate failure for symlink creation
      local original_execute = os.execute
      os.execute = function(command)
        if command:match("^ln") then
          return 1  -- Return error code
        end
        return original_execute(command)
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Try to enable a plugin (which creates a symlink)
      core.enable({"plugin1"}, false)
      
      -- Restore original function
      os.execute = original_execute
      printer.restore()
      
      -- Verify the symlink was not created
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
    end)
    
    it("should handle failure when removing files", function()
      -- Setup test fixture with enabled plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        },
        plugins = {
          { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" }
        }
      })
      
      -- Override os.execute to simulate failure for file removal
      local original_execute = os.execute
      os.execute = function(command)
        if command:match("^rm") then
          return 1  -- Return error code
        end
        return original_execute(command)
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Try to disable a plugin (which removes a symlink)
      core.disable({"plugin1"}, false)
      
      -- Restore original function
      os.execute = original_execute
      printer.restore()
      
      -- Verify the symlink still exists (wasn't removed due to error)
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
    end)
    
    it("should handle failure when reading files", function()
      -- Setup test fixture
      utils.setup_fixture({
        plugins = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        }
      })
      
      -- Override io.open to simulate failure for reading
      local original_open = io.open
      io.open = function(path, mode)
        if mode == "r" then
          return nil  -- Simulate failure
        end
        return original_open(path, mode)
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call init which tries to read plugin files
      local result = core.init()
      
      -- Restore original function
      io.open = original_open
      printer.restore()
      
      -- Verify the function handled the error
      assert.is_false(result)
      
      -- Check for error message
      local error_found = false
      for _, line in ipairs(printer.output) do
        if line:match("Error reading file:") then
          error_found = true
          break
        end
      end
      assert.is_true(error_found, "Expected error message about file reading")
    end)
    
    it("should handle failure when writing files", function()
      -- Setup test fixture
      utils.setup_fixture({
        plugins = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        }
      })
      
      -- Override io.open to simulate failure for writing
      local original_open = io.open
      io.open = function(path, mode)
        if mode == "w" then
          return nil  -- Simulate failure
        end
        return original_open(path, mode)
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call init which tries to write plugin files
      local result = core.init()
      
      -- Restore original function
      io.open = original_open
      printer.restore()
      
      -- Verify the function handled the error
      assert.is_false(result)
    end)
  end)
  
  describe("corrupted plugin files", function()
    it("should handle empty plugin files", function()
      -- Setup test fixture with an empty plugin file
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "empty_plugin", content = "" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Try to enable the empty plugin
      local result = core.enable({"empty_plugin"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify the plugin was enabled (empty files are valid)
      assert.is_true(result)
      assert.equals(cfg.available_dir .. "/empty_plugin.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/empty_plugin.lua"))
      
      -- Verify output
      assert.equals("Enabled plugin: empty_plugin.lua", printer.output[1])
    end)
    
    it("should handle plugin files with syntax errors", function()
      -- Setup test fixture with a plugin containing syntax errors
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "syntax_error_plugin", content = "local x = { unclosed table" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Try to enable the plugin with syntax errors
      local result = core.enable({"syntax_error_plugin"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify the plugin was enabled (syntax errors are only detected at runtime)
      assert.is_true(result)
      assert.equals(cfg.available_dir .. "/syntax_error_plugin.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/syntax_error_plugin.lua"))
      
      -- Verify output
      assert.equals("Enabled plugin: syntax_error_plugin.lua", printer.output[1])
    end)
    
    it("should handle very large plugin files", function()
      -- Create a large content string (100KB)
      local large_content = string.rep("-- This is a very large plugin file\n", 5000)
      
      -- Setup test fixture with a large plugin file
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "large_plugin", content = large_content }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Try to enable the large plugin
      local result = core.enable({"large_plugin"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify the plugin was enabled
      assert.is_true(result)
      assert.equals(cfg.available_dir .. "/large_plugin.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/large_plugin.lua"))
      
      -- Verify output
      assert.equals("Enabled plugin: large_plugin.lua", printer.output[1])
    end)
  end)
  
  describe("invalid symlinks", function()
    it("should handle symlinks pointing to non-existent targets", function()
      -- Setup test fixture with a broken symlink
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        },
        plugins = {
          { name = "broken_link", is_link = true, links_to = "/non/existent/path.lua" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Run health check to detect broken symlinks
      local result = core.health_check(false)
      
      -- Restore print
      printer.restore()
      
      -- Verify health check detected the issue
      assert.is_false(result)
      
      -- Check for warning message
      local warning_found = false
      for _, line in ipairs(printer.output) do
        if line:match("Warning: broken_link.lua points to a non%-existent file") then
          warning_found = true
          break
        end
      end
      assert.is_true(warning_found, "Expected warning about broken symlink")
      
      -- Test with fix option
      printer = utils.capture_print()
      result = core.health_check(true)
      printer.restore()
      
      -- Verify the health check result after fixing
      assert.is_true(result, "Health check should pass after fixing the issues")
      
      -- Verify the broken symlink was removed
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_link.lua"))
    end)
    
    it("should handle circular symlinks", function()
      -- Setup test fixture with a circular symlink (points to itself)
      local cfg = utils.setup_fixture({})
      
      -- Create a circular symlink manually
      local link_path = cfg.plugins_dir .. "/circular.lua"
      utils.fs_mock.set_symlink(link_path, link_path)
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Run health check to detect circular symlinks
      local result = core.health_check(false)
      
      -- Restore print
      printer.restore()
      
      -- Verify health check detected the issue
      assert.is_false(result)
      
      -- Test with fix option
      printer = utils.capture_print()
      result = core.health_check(true)
      printer.restore()
      
      -- Verify the health check result after fixing
      assert.is_true(result, "Health check should pass after fixing the issues")
      
      -- Verify the circular symlink was removed
      assert.is_nil(utils.fs_mock.get_symlink(link_path))
    end)
    
    it("should handle symlinks pointing to directories", function()
      -- Setup test fixture
      local cfg = utils.setup_fixture({})
      
      -- Create a directory in plugins-available
      utils.fs_mock.set_directory(cfg.available_dir .. "/directory")
      
      -- Create a symlink to the directory
      local link_path = cfg.plugins_dir .. "/dir_link.lua"
      utils.fs_mock.set_symlink(cfg.available_dir .. "/directory", link_path)
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Run health check to detect directory symlinks
      local result = core.health_check(false)
      
      -- Restore print
      printer.restore()
      
      -- Verify health check detected the issue
      assert.is_false(result)
      
      -- Check for warning message (this will be detected as a broken symlink)
      local warning_found = false
      for _, line in ipairs(printer.output) do
        if line:match("Warning: dir_link.lua points to a non%-existent file") then
          warning_found = true
          break
        end
      end
      assert.is_true(warning_found, "Expected warning about symlink to directory")
      
      -- Test with fix option
      printer = utils.capture_print()
      result = core.health_check(true)
      printer.restore()
      
      -- Verify the health check result after fixing
      assert.is_true(result, "Health check should pass after fixing the issues")
      
      -- Verify the directory symlink was removed
      assert.is_nil(utils.fs_mock.get_symlink(link_path))
    end)
  end)
end)
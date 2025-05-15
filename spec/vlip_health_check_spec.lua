-- Tests for the health_check command
-- Run with: busted spec/vlip_health_check_spec.lua

local utils = require("spec.utils")

describe("vlip health_check command", function()
  local core
  local cli
  
  setup(function()
    -- Add the project's lua directory to the package path
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
    cli = require("vlip.cli")
  end)
  
  after_each(function()
    -- Teardown filesystem mocking
    utils.teardown_fixture()
  end)
  
  describe("core.health_check()", function()
    it("should detect non-symlink files in plugins directory", function()
      -- Setup test fixture with a regular file in the plugins directory
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        },
        plugins = {
          { name = "plugin1", is_link = false, content = "-- Regular file content" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      local result = core.health_check(false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the issue was detected
      assert.is_false(result)
      
      -- Verify that the file exists in the plugins directory
      assert.is_not_nil(utils.fs_mock.get_file(cfg.plugins_dir .. "/plugin1.lua"))
      
      -- Verify output
      assert.equals("Warning: plugin1.lua is not a symlink", printer.output[1])
      assert.equals("Health check found 1 issues", printer.output[2])
      assert.equals("Run with --fix to automatically resolve issues", printer.output[3])
    end)
    
    it("should detect broken symlinks", function()
      -- Setup test fixture with a broken symlink
      local cfg = utils.setup_fixture({
        plugins = {
          {
            name = "broken_plugin",
            is_link = true,
            links_to = "/non/existent/path/plugin.lua"
          }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      local result = core.health_check(false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the issue was detected
      assert.is_false(result)
      
      -- Verify that the broken symlink exists
      assert.equals("/non/existent/path/plugin.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua"))
      
      -- Verify output
      assert.equals("Warning: broken_plugin.lua points to a non-existent file", printer.output[1])
      assert.equals("Health check found 1 issues", printer.output[2])
      assert.equals("Run with --fix to automatically resolve issues", printer.output[3])
    end)
    
    it("should fix non-symlink files with --fix option", function()
      -- Setup test fixture with a regular file in the plugins directory
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        },
        plugins = {
          { name = "plugin1", is_link = false, content = "-- Regular file content" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with fix=true
      local result = core.health_check(true)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the issue was fixed
      assert.is_true(result)
      
      -- Verify that the file was removed
      assert.is_nil(utils.fs_mock.get_file(cfg.plugins_dir .. "/plugin1.lua"))
      
      -- Verify output
      assert.equals("Warning: plugin1.lua is not a symlink", printer.output[1])
      assert.equals("Removed non-symlink: plugin1.lua", printer.output[2])
      assert.equals("Health check found 1 issues", printer.output[3])
      assert.equals("Fixed 1 out of 1 issues", printer.output[4])
    end)
    
    it("should fix broken symlinks with --fix option", function()
      -- Setup test fixture with a broken symlink
      local cfg = utils.setup_fixture({
        plugins = {
          {
            name = "broken_plugin",
            is_link = true,
            links_to = "/non/existent/path/plugin.lua"
          }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with fix=true
      local result = core.health_check(true)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the issue was fixed
      assert.is_true(result)
      
      -- Verify that the symlink was removed
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua"))
      
      -- Verify output
      assert.equals("Warning: broken_plugin.lua points to a non-existent file", printer.output[1])
      assert.equals("Removed broken symlink: broken_plugin.lua", printer.output[2])
      assert.equals("Health check found 1 issues", printer.output[3])
      assert.equals("Fixed 1 out of 1 issues", printer.output[4])
    end)
    
    it("should handle health_check after manually modifying the plugins directory", function()
      -- Setup test fixture with valid plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" }
        },
        plugins = {
          {
            name = "plugin1",
            is_link = true,
            links_to = "/mock/config/lua/plugins-available/plugin1.lua"
          },
          {
            name = "plugin2",
            is_link = true,
            links_to = "/mock/config/lua/plugins-available/plugin2.lua"
          }
        }
      })
      
      -- Manually modify the plugins directory
      utils.fs_mock.set_file(cfg.plugins_dir .. "/manual_plugin.lua", "-- Manually added plugin")
      utils.fs_mock.set_symlink("/non/existent/path.lua", cfg.plugins_dir .. "/broken_manual.lua")
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      local result = core.health_check(false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that issues were detected
      assert.is_false(result)
      
      -- Verify output - we don't know the exact order, so check that all issues are mentioned
      local issues_found = {
        ["manual_plugin.lua"] = false,
        ["broken_manual.lua"] = false
      }
      
      for _, line in ipairs(printer.output) do
        if line:match("Warning: manual_plugin.lua is not a symlink") then
          issues_found["manual_plugin.lua"] = true
        elseif line:match("Warning: broken_manual.lua points to a non%-existent file") then
          issues_found["broken_manual.lua"] = true
        end
      end
      
      assert.is_true(issues_found["manual_plugin.lua"])
      assert.is_true(issues_found["broken_manual.lua"])
      assert.equals("Health check found 2 issues", printer.output[3])
    end)
    
    it("should handle health_check with mixed valid and invalid plugins", function()
      -- Setup test fixture with mixed valid and invalid plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "valid_plugin", content = "-- Valid plugin content" }
        },
        plugins = {
          {
            name = "valid_plugin",
            is_link = true,
            links_to = "/mock/config/lua/plugins-available/valid_plugin.lua"
          },
          { name = "invalid_plugin", is_link = false, content = "-- Invalid plugin content" },
          {
            name = "broken_plugin",
            is_link = true,
            links_to = "/non/existent/path/plugin.lua"
          }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with fix=true
      local result = core.health_check(true)
      
      -- Restore print
      printer.restore()
      
      -- Verify that issues were fixed
      assert.is_true(result)
      
      -- Verify that invalid plugins were removed
      assert.is_nil(utils.fs_mock.get_file(cfg.plugins_dir .. "/invalid_plugin.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua"))
      
      -- Verify that valid plugin remains
      assert.equals(cfg.available_dir .. "/valid_plugin.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/valid_plugin.lua"))
      
      -- Verify output - we don't know the exact order, so check that all issues are mentioned
      local issues_found = {
        ["invalid_plugin.lua"] = false,
        ["broken_plugin.lua"] = false
      }
      
      for _, line in ipairs(printer.output) do
        if line:match("Warning: invalid_plugin.lua is not a symlink") then
          issues_found["invalid_plugin.lua"] = true
        elseif line:match("Warning: broken_plugin.lua points to a non%-existent file") then
          issues_found["broken_plugin.lua"] = true
        end
      end
      
      assert.is_true(issues_found["invalid_plugin.lua"])
      assert.is_true(issues_found["broken_plugin.lua"])
      assert.equals("Health check found 2 issues", printer.output[5])
      assert.equals("Fixed 2 out of 2 issues", printer.output[6])
    end)
  end)
  
  describe("cli.parse_args() with health_check", function()
    it("should call core.health_check() when given health_check command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.health_check
      local original_health_check = core.health_check
      local health_check_called = false
      local fix_arg
      
      core.health_check = function(fix)
        health_check_called = true
        fix_arg = fix
        return true
      end
      
      -- Call the function
      cli.parse_args({"health-check"})
      
      -- Restore original function
      core.health_check = original_health_check
      
      -- Verify that health_check was called with the correct arguments
      assert.is_true(health_check_called)
      assert.is_false(fix_arg)
    end)
    
    it("should pass --fix flag to core.health_check()", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.health_check
      local original_health_check = core.health_check
      local health_check_called = false
      local fix_arg
      
      core.health_check = function(fix)
        health_check_called = true
        fix_arg = fix
        return true
      end
      
      -- Call the function
      cli.parse_args({"health-check", "--fix"})
      
      -- Restore original function
      core.health_check = original_health_check
      
      -- Verify that health_check was called with the correct arguments
      assert.is_true(health_check_called)
      assert.is_true(fix_arg)
    end)
    
    it("should return true when health_check command succeeds", function()
      -- Setup test fixture with valid plugins
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        },
        plugins = {
          {
            name = "plugin1",
            is_link = true,
            links_to = "/mock/config/lua/plugins-available/plugin1.lua"
          }
        }
      })
      
      -- Spy on core.health_check
      local original_health_check = core.health_check
      core.health_check = function(_)
        return true
      end
      
      -- Call the function and capture result
      local result = cli.parse_args({"health-check"})
      
      -- Restore original function
      core.health_check = original_health_check
      
      -- Verify result
      assert.is_true(result)
    end)
  end)
end)
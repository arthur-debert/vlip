-- Tests for CLI argument parsing
-- Run with: busted spec/vlip_cli_args_spec.lua

-- luacheck: globals io os

local utils = require("spec.utils")

describe("VLIP CLI argument parsing", function()
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
  
  describe("invalid commands", function()
    it("should handle non-existent commands", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with a non-existent command
      local result = cli.parse_args({"non_existent_command"})
      
      -- Restore print
      printer.restore()
      
      -- Verify result
      assert.is_false(result)
      
      -- Verify output contains the expected error message
      local found = false
      for _, line in ipairs(printer.output) do
        if line:match("Unknown command: non_existent_command") then
          found = true
          break
        end
      end
      assert.is_true(found, "Expected to find 'Unknown command' message")
    end)
    
    it("should handle empty command list", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with an empty command list
      local result = cli.parse_args({})
      
      -- Restore print
      printer.restore()
      
      -- Verify result
      assert.is_false(result)
      
      -- Verify output contains the usage information
      local found = false
      for _, line in ipairs(printer.output) do
        if line:match("Usage: vlip <command>") then
          found = true
          break
        end
      end
      assert.is_true(found, "Expected to find usage information")
    end)
  end)
  
  describe("invalid arguments", function()
    it("should handle invalid arguments for enable command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.enable
      local original_enable = core.enable
      local enable_called = false
      local plugins_arg = nil
      local all_arg = nil
      
      core.enable = function(plugins, all)
        enable_called = true
        plugins_arg = plugins
        all_arg = all
        return true
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with invalid arguments
      local result = cli.parse_args({"enable", "--invalid-flag"})
      
      -- Restore original function and print
      core.enable = original_enable
      printer.restore()
      
      -- Verify that enable was called with the correct arguments
      assert.is_true(enable_called)
      assert.is_true(#plugins_arg == 1)
      assert.equals("--invalid-flag", plugins_arg[1])
      assert.is_false(all_arg)
      
      -- Verify result
      assert.is_true(result)
    end)
    
    it("should handle invalid arguments for disable command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.disable
      local original_disable = core.disable
      local disable_called = false
      local plugins_arg = nil
      local all_arg = nil
      
      core.disable = function(plugins, all)
        disable_called = true
        plugins_arg = plugins
        all_arg = all
        return true
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with invalid arguments
      local result = cli.parse_args({"disable", "--invalid-flag"})
      
      -- Restore original function and print
      core.disable = original_disable
      printer.restore()
      
      -- Verify that disable was called with the correct arguments
      assert.is_true(disable_called)
      assert.is_true(#plugins_arg == 1)
      assert.equals("--invalid-flag", plugins_arg[1])
      assert.is_false(all_arg)
      
      -- Verify result
      assert.is_true(result)
    end)
  end)
  
  describe("missing required arguments", function()
    it("should handle missing plugin name for enable command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.enable
      local original_enable = core.enable
      local enable_called = false
      local plugins_arg = nil
      local all_arg = nil
      
      core.enable = function(plugins, all)
        enable_called = true
        plugins_arg = plugins
        all_arg = all
        return true
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with no plugin name
      local result = cli.parse_args({"enable"})
      
      -- Restore original function and print
      core.enable = original_enable
      printer.restore()
      
      -- Verify that enable was called with empty plugins list
      assert.is_true(enable_called)
      assert.is_true(#plugins_arg == 0)
      assert.is_false(all_arg)
      
      -- Verify result
      assert.is_true(result)
    end)
    
    it("should handle missing plugin name for disable command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.disable
      local original_disable = core.disable
      local disable_called = false
      local plugins_arg = nil
      local all_arg = nil
      
      core.disable = function(plugins, all)
        disable_called = true
        plugins_arg = plugins
        all_arg = all
        return true
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with no plugin name
      local result = cli.parse_args({"disable"})
      
      -- Restore original function and print
      core.disable = original_disable
      printer.restore()
      
      -- Verify that disable was called with empty plugins list
      assert.is_true(disable_called)
      assert.is_true(#plugins_arg == 0)
      assert.is_false(all_arg)
      
      -- Verify result
      assert.is_true(result)
    end)
  end)
  
  describe("extra/unexpected arguments", function()
    it("should handle extra arguments for init command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.init
      local original_init = core.init
      local init_called = false
      
      core.init = function()
        init_called = true
        return true
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with extra arguments
      local result = cli.parse_args({"init", "extra1", "extra2"})
      
      -- Restore original function and print
      core.init = original_init
      printer.restore()
      
      -- Verify that init was called
      assert.is_true(init_called)
      
      -- Verify result
      assert.is_true(result)
    end)
    
    it("should handle extra arguments for health-check command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.health_check
      local original_health_check = core.health_check
      local health_check_called = false
      local fix_arg = nil
      
      core.health_check = function(fix)
        health_check_called = true
        fix_arg = fix
        return true
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with extra arguments
      local result = cli.parse_args({"health-check", "--fix", "extra1", "extra2"})
      
      -- Restore original function and print
      core.health_check = original_health_check
      printer.restore()
      
      -- Verify that health_check was called with fix=true
      assert.is_true(health_check_called)
      assert.is_true(fix_arg)
      
      -- Verify result
      assert.is_true(result)
    end)
  end)
  
  describe("help command and version display", function()
    it("should display usage information when no arguments are provided", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with no arguments
      local result = cli.parse_args({})
      
      -- Restore print
      printer.restore()
      
      -- Verify result
      assert.is_false(result)
      
      -- Verify output contains the usage information
      local found = false
      for _, line in ipairs(printer.output) do
        if line:match("Usage: vlip <command>") then
          found = true
          break
        end
      end
      assert.is_true(found, "Expected to find usage information")
    end)
    
    it("should display version information for --version flag", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with --version flag
      local result = cli.parse_args({"--version"})
      
      -- Restore print
      printer.restore()
      
      -- Verify result
      assert.is_true(result)
      
      -- Verify output contains the version information
      local found = false
      for _, line in ipairs(printer.output) do
        if line:match("vlip version") then
          found = true
          break
        end
      end
      assert.is_true(found, "Expected to find version information")
    end)
  end)
  
  describe("combined flags", function()
    it("should handle enable --all with additional plugin names", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.enable
      local original_enable = core.enable
      local enable_called = false
      local plugins_arg = nil
      local all_arg = nil
      
      core.enable = function(plugins, all)
        enable_called = true
        plugins_arg = plugins
        all_arg = all
        return true
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with --all flag and plugin names
      local result = cli.parse_args({"enable", "--all", "plugin1", "plugin2"})
      
      -- Restore original function and print
      core.enable = original_enable
      printer.restore()
      
      -- Verify that enable was called with the correct arguments
      assert.is_true(enable_called)
      assert.is_true(#plugins_arg == 2)
      assert.equals("plugin1", plugins_arg[1])
      assert.equals("plugin2", plugins_arg[2])
      assert.is_true(all_arg)
      
      -- Verify result
      assert.is_true(result)
    end)
    
    it("should handle disable --all with additional plugin names", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.disable
      local original_disable = core.disable
      local disable_called = false
      local plugins_arg = nil
      local all_arg = nil
      
      core.disable = function(plugins, all)
        disable_called = true
        plugins_arg = plugins
        all_arg = all
        return true
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function with --all flag and plugin names
      local result = cli.parse_args({"disable", "--all", "plugin1", "plugin2"})
      
      -- Restore original function and print
      core.disable = original_disable
      printer.restore()
      
      -- Verify that disable was called with the correct arguments
      assert.is_true(disable_called)
      assert.is_true(#plugins_arg == 2)
      assert.equals("plugin1", plugins_arg[1])
      assert.equals("plugin2", plugins_arg[2])
      assert.is_true(all_arg)
      
      -- Verify result
      assert.is_true(result)
    end)
  end)
end)
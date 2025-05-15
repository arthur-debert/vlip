-- Tests for CLI argument parsing
local utils = require("spec.utils")

describe("vlip CLI argument parsing", function()
  local core
  local cli
  
  setup(function()
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
    cli = require("vlip.cli")
  end)
  
  after_each(function()
    utils.teardown_fixture()
  end)
  
  describe("enable command", function()
    it("should call core.enable() when given enable command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.enable
      local original_enable = core.enable
      local enable_called = false
      local plugins_arg
      local all_arg
      
      core.enable = function(plugins, all)
        enable_called = true
        plugins_arg = plugins
        all_arg = all
      end
      
      -- Call the function
      cli.parse_args({"enable", "plugin1", "plugin2"})
      
      -- Restore original function
      core.enable = original_enable
      
      -- Verify that enable was called with the correct arguments
      assert.is_true(enable_called)
      assert.equals(2, #plugins_arg)
      assert.equals("plugin1", plugins_arg[1])
      assert.equals("plugin2", plugins_arg[2])
      assert.is_false(all_arg)
    end)
    
    it("should pass --all flag to core.enable()", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.enable
      local original_enable = core.enable
      local enable_called = false
      local plugins_arg
      local all_arg
      
      core.enable = function(plugins, all)
        enable_called = true
        plugins_arg = plugins
        all_arg = all
      end
      
      -- Call the function
      cli.parse_args({"enable", "--all"})
      
      -- Restore original function
      core.enable = original_enable
      
      -- Verify that enable was called with the correct arguments
      assert.is_true(enable_called)
      assert.equals(0, #plugins_arg)
      assert.is_true(all_arg)
    end)
  end)
  
  describe("disable command", function()
    it("should call core.disable() when given disable command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.disable
      local original_disable = core.disable
      local disable_called = false
      local plugins_arg
      local all_arg
      
      core.disable = function(plugins, all)
        disable_called = true
        plugins_arg = plugins
        all_arg = all
      end
      
      -- Call the function
      cli.parse_args({"disable", "plugin1", "plugin2"})
      
      -- Restore original function
      core.disable = original_disable
      
      -- Verify that disable was called with the correct arguments
      assert.is_true(disable_called)
      assert.equals(2, #plugins_arg)
      assert.equals("plugin1", plugins_arg[1])
      assert.equals("plugin2", plugins_arg[2])
      assert.is_false(all_arg)
    end)
    
    it("should pass --all flag to core.disable()", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.disable
      local original_disable = core.disable
      local disable_called = false
      local plugins_arg
      local all_arg
      
      core.disable = function(plugins, all)
        disable_called = true
        plugins_arg = plugins
        all_arg = all
      end
      
      -- Call the function
      cli.parse_args({"disable", "--all"})
      
      -- Restore original function
      core.disable = original_disable
      
      -- Verify that disable was called with the correct arguments
      assert.is_true(disable_called)
      assert.equals(0, #plugins_arg)
      assert.is_true(all_arg)
    end)
  end)
  
  describe("list commands", function()
    it("should call core.list_available() when given list-available command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.list_available
      local original_list_available = core.list_available
      local list_available_called = false
      
      core.list_available = function()
        list_available_called = true
      end
      
      -- Call the function
      cli.parse_args({"list-available"})
      
      -- Restore original function
      core.list_available = original_list_available
      
      -- Verify that list_available was called
      assert.is_true(list_available_called)
    end)
    
    it("should call core.list_enabled() when given list-enabled command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.list_enabled
      local original_list_enabled = core.list_enabled
      local list_enabled_called = false
      
      core.list_enabled = function()
        list_enabled_called = true
      end
      
      -- Call the function
      cli.parse_args({"list-enabled"})
      
      -- Restore original function
      core.list_enabled = original_list_enabled
      
      -- Verify that list_enabled was called
      assert.is_true(list_enabled_called)
    end)
  end)
  
  describe("command success", function()
    it("should return true when commands succeed", function()
      -- Setup test fixture with a plugin
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        },
        plugins = {
          { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" }
        }
      })
      
      -- Test each command
      assert.is_true(cli.parse_args({"enable", "plugin1"}))
      assert.is_true(cli.parse_args({"disable", "plugin1"}))
      assert.is_true(cli.parse_args({"list-available"}))
      assert.is_true(cli.parse_args({"list-enabled"}))
    end)
  end)
end)
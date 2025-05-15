-- Tests for the list-enabled command
-- Run with: busted spec/vlip_list_enabled_spec.lua

local utils = require("spec.utils")

describe("vlip list-enabled command", function()
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
  
  describe("core.list_enabled()", function()
    it("should list all enabled plugins", function()
      -- Setup test fixture with multiple plugins, some enabled
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" },
          { name = "plugin3.lua", content = "-- Plugin 3 content" }
        },
        plugins = {
          { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" },
          { name = "plugin3.lua", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin3.lua" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.list_enabled()
      
      -- Restore print
      printer.restore()
      
      -- Verify output
      assert.is_true(#printer.output >= 3) -- Header + 2 plugins
      assert.equals("Enabled plugins:", printer.output[1])
      
      -- Check that only enabled plugins are listed
      local plugins_found = {
        plugin1 = false,
        plugin2 = false,
        plugin3 = false
      }
      
      for i = 2, #printer.output do
        local name = printer.output[i]:match("%s+(.+)$")
        if name then
          plugins_found[name] = true
        end
      end
      
      assert.is_true(plugins_found.plugin1)
      assert.is_false(plugins_found.plugin2)
      assert.is_true(plugins_found.plugin3)
    end)
    
    it("should handle no enabled plugins", function()
      -- Setup test fixture with available plugins but none enabled
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.list_enabled()
      
      -- Restore print
      printer.restore()
      
      -- Verify output
      assert.equals(1, #printer.output) -- Only the header
      assert.equals("Enabled plugins:", printer.output[1])
    end)
  end)
  
  describe("cli.parse_args() with list-enabled", function()
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
    
    it("should return true when list-enabled command succeeds", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Call the function and capture result
      local result = cli.parse_args({"list-enabled"})
      
      -- Verify result
      assert.is_true(result)
    end)
  end)
end)
-- Tests for the list-available command
local utils = require("spec.utils")

describe("vlip list-available command", function()
  local core
  
  setup(function()
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
  end)
  
  after_each(function()
    utils.teardown_fixture()
  end)
  
  describe("core.list_available()", function()
    it("should list all available plugins", function()
      -- Setup test fixture with multiple plugins
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" },
          { name = "plugin3.lua", content = "-- Plugin 3 content" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.list_available()
      
      -- Restore print
      printer.restore()
      
      -- Verify output
      assert.is_true(#printer.output >= 4) -- Header + 3 plugins
      assert.equals("Available plugins:", printer.output[1])
      
      -- Check that all plugins are listed
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
      assert.is_true(plugins_found.plugin2)
      assert.is_true(plugins_found.plugin3)
    end)
    
    it("should handle no available plugins", function()
      -- Setup test fixture with no plugins
      utils.setup_fixture({})
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.list_available()
      
      -- Restore print
      printer.restore()
      
      -- Verify output
      assert.equals(1, #printer.output) -- Only the header
      assert.equals("Available plugins:", printer.output[1])
    end)
  end)
end)
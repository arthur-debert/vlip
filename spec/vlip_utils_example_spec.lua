-- Example of using the utils module with VLIP
-- Run with: busted spec/vlip_utils_example_spec.lua

local utils = require("spec.utils")

describe("VLIP with utils module", function()
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
  
  describe("Plugin listing", function()
    it("should list available plugins", function()
      -- Setup test fixture
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
    
    it("should list enabled plugins", function()
      -- Setup test fixture with symlinks from plugins to plugins-available
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
      
      -- Check that only the enabled plugins are listed
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
  end)
  
  describe("Plugin management", function()
    it("should enable a plugin", function()
      -- Setup test fixture
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.enable({"plugin1"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the symlink was created
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      
      -- Verify output
      assert.equals("Enabled plugin: plugin1.lua", printer.output[1])
    end)
    
    it("should disable a plugin", function()
      -- Setup test fixture with an enabled plugin
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        },
        plugins = {
          { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.disable({"plugin1"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the symlink was removed
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      
      -- Verify output
      assert.equals("Disabled plugin: plugin1.lua", printer.output[1])
    end)
  end)
end)
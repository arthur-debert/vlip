-- Tests for the enable command
-- Run with: busted spec/vlip_enable_spec.lua

local utils = require("spec.utils")

describe("vlip enable command", function()
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
  
  describe("core.enable()", function()
    it("should enable a single plugin", function()
      -- Setup test fixture with available plugins
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
    
    it("should enable multiple plugins", function()
      -- Setup test fixture with available plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" },
          { name = "plugin3.lua", content = "-- Plugin 3 content" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.enable({"plugin1", "plugin3.lua"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the symlinks were created
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin3.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))
      
      -- Verify plugin2 was not enabled
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      
      -- Verify output
      assert.equals("Enabled plugin: plugin1.lua", printer.output[1])
      assert.equals("Enabled plugin: plugin3.lua", printer.output[2])
    end)
    
    it("should enable all plugins with --all flag", function()
      -- Setup test fixture with available plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" },
          { name = "plugin3.lua", content = "-- Plugin 3 content" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.enable({}, true)
      
      -- Restore print
      printer.restore()
      
      -- Verify that all symlinks were created
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.equals(cfg.available_dir .. "/plugin3.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))
      
      -- Verify output - we don't know the exact order, so check that all plugins are mentioned
      local plugins_enabled = {
        ["plugin1.lua"] = false,
        ["plugin2.lua"] = false,
        ["plugin3.lua"] = false
      }
      
      for _, line in ipairs(printer.output) do
        for plugin, _ in pairs(plugins_enabled) do
          if line == "Enabled plugin: " .. plugin then
            plugins_enabled[plugin] = true
          end
        end
      end
      
      assert.is_true(plugins_enabled["plugin1.lua"])
      assert.is_true(plugins_enabled["plugin2.lua"])
      assert.is_true(plugins_enabled["plugin3.lua"])
    end)
    
    it("should handle non-existent plugins", function()
      -- Setup test fixture with available plugins
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.enable({"non-existent-plugin"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify output
      assert.equals("Plugin not found: non-existent-plugin.lua", printer.output[1])
    end)
    
    it("should handle already enabled plugins", function()
      -- Setup test fixture with available and enabled plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" }
        },
        plugins = {
          { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.enable({"plugin1", "plugin2"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that plugin2 was enabled
      assert.equals(cfg.available_dir .. "/plugin2.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      
      -- Verify output
      assert.equals("Plugin already enabled: plugin1.lua", printer.output[1])
      assert.equals("Enabled plugin: plugin2.lua", printer.output[2])
    end)
  end)
  
  describe("cli.parse_args() with enable", function()
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
    
    it("should return true when enable command succeeds", function()
      -- Setup test fixture
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        }
      })
      
      -- Call the function and capture result
      local result = cli.parse_args({"enable", "plugin1"})
      
      -- Verify result
      assert.is_true(result)
    end)
  end)
end)
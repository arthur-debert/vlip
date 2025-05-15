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
  
  describe("enable command with invalid plugins", function()
    it("should enable a plugin that exists but has invalid content", function()
      -- Setup test fixture with available plugins, one with invalid Lua syntax
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "invalid_plugin", content = "-- This is not valid Lua syntax\nlocal x = {" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.enable({"invalid_plugin"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the symlink was created despite invalid content
      assert.equals(cfg.available_dir .. "/invalid_plugin.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/invalid_plugin.lua"))
      
      -- Verify output
      assert.equals("Enabled plugin: invalid_plugin.lua", printer.output[1])
    end)
    
    it("should enable plugins when the plugins directory doesn't exist", function()
      -- Setup test fixture without plugins directory
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        }
      })
      
      -- Remove the plugins directory
      utils.fs_mock.set_directory(cfg.plugins_dir, nil)
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.enable({"plugin1"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the symlink was created and directory was created
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.is_true(utils.fs_mock.directory_exists(cfg.plugins_dir))
      
      -- Verify output
      assert.equals("Enabled plugin: plugin1.lua", printer.output[1])
    end)
    
    it("should enable a plugin with the same name as an existing non-symlink file", function()
      -- Setup test fixture with a non-symlink file in plugins directory
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        },
        plugins = {
          { name = "plugin1", content = "-- Different content", is_link = false }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.enable({"plugin1"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify output - should indicate plugin is already enabled
      assert.equals("Plugin already enabled: plugin1.lua", printer.output[1])
      
      -- Verify that the original file was not replaced with a symlink
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
    end)
    
    it("should enable a plugin when the available-plugins directory doesn't exist", function()
      -- Setup test fixture without available-plugins directory
      local cfg = utils.setup_fixture({})
      
      -- Remove the available-plugins directory
      utils.fs_mock.set_directory(cfg.available_dir, nil)
      
      -- Create a plugin file directly in the available directory
      utils.fs_mock.set_file(cfg.available_dir .. "/plugin1.lua", "-- Plugin 1 content")
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.enable({"plugin1"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the directory was created and symlink was created
      assert.is_true(utils.fs_mock.directory_exists(cfg.available_dir))
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      
      -- Verify output
      assert.equals("Enabled plugin: plugin1.lua", printer.output[1])
    end)
    
    it("should enable a plugin with a name containing special characters", function()
      -- Setup test fixture with a plugin with special characters in name
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin-with-dashes", content = "-- Plugin with dashes" },
          { name = "plugin_with_underscores", content = "-- Plugin with underscores" },
          { name = "plugin.with.dots", content = "-- Plugin with dots" },
          { name = "plugin with spaces", content = "-- Plugin with spaces" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function for each plugin
      core.enable({"plugin-with-dashes", "plugin_with_underscores",
                  "plugin.with.dots", "plugin with spaces"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the symlinks were created
      assert.equals(cfg.available_dir .. "/plugin-with-dashes.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin-with-dashes.lua"))
      assert.equals(cfg.available_dir .. "/plugin_with_underscores.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin_with_underscores.lua"))
      assert.equals(cfg.available_dir .. "/plugin.with.dots.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin.with.dots.lua"))
      assert.equals(cfg.available_dir .. "/plugin with spaces.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin with spaces.lua"))
      
      -- Verify output - we don't know the exact order, so check that all plugins are mentioned
      local plugins_enabled = {
        ["plugin-with-dashes.lua"] = false,
        ["plugin_with_underscores.lua"] = false,
        ["plugin.with.dots.lua"] = false,
        ["plugin with spaces.lua"] = false
      }
      
      for _, line in ipairs(printer.output) do
        for plugin, _ in pairs(plugins_enabled) do
          if line == "Enabled plugin: " .. plugin then
            plugins_enabled[plugin] = true
          end
        end
      end
      
      assert.is_true(plugins_enabled["plugin-with-dashes.lua"])
      assert.is_true(plugins_enabled["plugin_with_underscores.lua"])
      assert.is_true(plugins_enabled["plugin.with.dots.lua"])
      assert.is_true(plugins_enabled["plugin with spaces.lua"])
    end)
  end)
end)
-- Tests for the disable command
-- Run with: busted spec/vlip_disable_spec.lua

local utils = require("spec.utils")

describe("vlip disable command", function()
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
  
  describe("core.disable()", function()
    it("should disable a single plugin", function()
      -- Setup test fixture with enabled plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" }
        },
        plugins = {
          { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" },
          { name = "plugin2", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin2.lua" }
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
      
      -- Verify that plugin2 is still enabled
      assert.equals(cfg.available_dir .. "/plugin2.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      
      -- Verify output
      assert.equals("Disabled plugin: plugin1.lua", printer.output[1])
    end)
    
    it("should disable multiple plugins", function()
      -- Setup test fixture with enabled plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" },
          { name = "plugin3.lua", content = "-- Plugin 3 content" }
        },
        plugins = {
          { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" },
          { name = "plugin2", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin2.lua" },
          { name = "plugin3.lua", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin3.lua" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.disable({"plugin1", "plugin3.lua"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the symlinks were removed
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))
      
      -- Verify that plugin2 is still enabled
      assert.equals(cfg.available_dir .. "/plugin2.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      
      -- Verify output
      assert.equals("Disabled plugin: plugin1.lua", printer.output[1])
      assert.equals("Disabled plugin: plugin3.lua", printer.output[2])
    end)
    
    it("should disable all plugins with --all flag", function()
      -- Setup test fixture with enabled plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" },
          { name = "plugin3.lua", content = "-- Plugin 3 content" }
        },
        plugins = {
          { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" },
          { name = "plugin2", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin2.lua" },
          { name = "plugin3.lua", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin3.lua" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.disable({}, true)
      
      -- Restore print
      printer.restore()
      
      -- Verify that all symlinks were removed
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))
      
      -- Verify output - we don't know the exact order, so check that all plugins are mentioned
      local plugins_disabled = {
        ["plugin1.lua"] = false,
        ["plugin2.lua"] = false,
        ["plugin3.lua"] = false
      }
      
      for _, line in ipairs(printer.output) do
        for plugin, _ in pairs(plugins_disabled) do
          if line == "Disabled plugin: " .. plugin then
            plugins_disabled[plugin] = true
          end
        end
      end
      
      assert.is_true(plugins_disabled["plugin1.lua"])
      assert.is_true(plugins_disabled["plugin2.lua"])
      assert.is_true(plugins_disabled["plugin3.lua"])
    end)
    
    it("should handle non-enabled plugins", function()
      -- Setup test fixture with some enabled plugins
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.disable({"plugin1"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify output
      assert.equals("Plugin not enabled: plugin1.lua", printer.output[1])
    end)
  end)
  
  describe("cli.parse_args() with disable", function()
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
    
    it("should return true when disable command succeeds", function()
      -- Setup test fixture
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        },
        plugins = {
          { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" }
        }
      })
      
      -- Call the function and capture result
      local result = cli.parse_args({"disable", "plugin1"})
      
      -- Verify result
      assert.is_true(result)
    end)
  end)
  
  describe("disable command with special cases", function()
    it("should disable plugins that are symlinks but point to non-existent targets", function()
      -- Setup test fixture with a plugin that points to a non-existent target
      local cfg = utils.setup_fixture({
        plugins = {
          { name = "broken_plugin", is_link = true, links_to = "/non/existent/path/plugin.lua" }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.disable({"broken_plugin"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the symlink was removed
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua"))
      
      -- Verify output
      assert.equals("Disabled plugin: broken_plugin.lua", printer.output[1])
    end)
    
    it("should disable plugins that aren't symlinks (regular files in the plugins directory)", function()
      -- Setup test fixture with a regular file in the plugins directory
      local cfg = utils.setup_fixture({
        plugins = {
          { name = "regular_file", content = "-- Regular file content", is_link = false }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.disable({"regular_file"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the file was removed
      assert.is_nil(utils.fs_mock.get_file(cfg.plugins_dir .. "/regular_file.lua"))
      
      -- Verify output
      assert.equals("Disabled plugin: regular_file.lua", printer.output[1])
    end)
    
    it("should disable a plugin with a name containing special characters", function()
      -- Setup test fixture with plugins with special characters in names
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin-with-dashes", content = "-- Plugin with dashes" },
          { name = "plugin_with_underscores", content = "-- Plugin with underscores" },
          { name = "plugin.with.dots", content = "-- Plugin with dots" },
          { name = "plugin with spaces", content = "-- Plugin with spaces" }
        },
        plugins = {
          {
            name = "plugin-with-dashes",
            is_link = true,
            links_to = "/mock/config/lua/plugins-available/plugin-with-dashes.lua"
          },
          {
            name = "plugin_with_underscores",
            is_link = true,
            links_to = "/mock/config/lua/plugins-available/plugin_with_underscores.lua"
          },
          {
            name = "plugin.with.dots",
            is_link = true,
            links_to = "/mock/config/lua/plugins-available/plugin.with.dots.lua"
          },
          {
            name = "plugin with spaces",
            is_link = true,
            links_to = "/mock/config/lua/plugins-available/plugin with spaces.lua"
          }
        }
      })
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function for each plugin
      core.disable({"plugin-with-dashes", "plugin_with_underscores",
                   "plugin.with.dots", "plugin with spaces"}, false)
      
      -- Restore print
      printer.restore()
      
      -- Verify that the symlinks were removed
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin-with-dashes.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin_with_underscores.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin.with.dots.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin with spaces.lua"))
      
      -- Verify output - we don't know the exact order, so check that all plugins are mentioned
      local plugins_disabled = {
        ["plugin-with-dashes.lua"] = false,
        ["plugin_with_underscores.lua"] = false,
        ["plugin.with.dots.lua"] = false,
        ["plugin with spaces.lua"] = false
      }
      
      for _, line in ipairs(printer.output) do
        for plugin, _ in pairs(plugins_disabled) do
          if line == "Disabled plugin: " .. plugin then
            plugins_disabled[plugin] = true
          end
        end
      end
      
      assert.is_true(plugins_disabled["plugin-with-dashes.lua"])
      assert.is_true(plugins_disabled["plugin_with_underscores.lua"])
      assert.is_true(plugins_disabled["plugin.with.dots.lua"])
      assert.is_true(plugins_disabled["plugin with spaces.lua"])
    end)
    
    it("should disable a plugin that was just enabled in the same session", function()
      -- Setup test fixture with available plugins
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        }
      })
      
      -- First enable the plugin
      core.enable({"plugin1"}, false)
      
      -- Verify that the plugin was enabled
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                   utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Now disable the plugin
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
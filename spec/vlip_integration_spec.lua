-- Integration tests for VLIP
-- Run with: busted spec/vlip_integration_spec.lua

-- luacheck: globals io os

local utils = require("spec.utils")

describe("VLIP integration tests", function()
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

  describe("workflow tests", function()
    it("should handle enable followed by disable for the same plugin", function()
      -- Setup test fixture
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" },
          { name = "plugin2.lua", content = "-- Plugin 2 content" }
        }
      })

      -- Verify initial state
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))

      -- Enable plugin1
      local enable_result = core.enable({ "plugin1.lua" }, false)
      assert.is_true(enable_result)

      -- Verify plugin1 is enabled
      assert.equals(cfg.available_dir .. "/plugin1.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))

      -- Disable plugin1
      local disable_result = core.disable({ "plugin1.lua" }, false)
      assert.is_true(disable_result)

      -- Verify plugin1 is disabled
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
    end)

    it("should detect and fix broken symlinks", function()
      -- Setup test fixture with a broken symlink in plugins directory
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" }
        },
        plugins = {
          {
            name = "broken_plugin.lua",
            is_link = true,
            links_to = "/non/existent/path.lua"
          }
        }
      })

      -- Verify the broken symlink exists
      assert.equals("/non/existent/path.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua"))

      -- Capture print output for health_check
      local printer = utils.capture_print()

      -- Run health_check with no fix
      local result = core.health_check(false)

      -- Restore print
      printer.restore()

      -- Verify health_check detected the issue
      assert.is_false(result)

      -- Check for appropriate warning message
      local found_warning = false
      for _, line in ipairs(printer.output) do
        if line:match("Warning: broken_plugin.lua points to a non%-existent file") then
          found_warning = true
          break
        end
      end
      assert.is_true(found_warning)

      -- Now run health_check with fix
      printer = utils.capture_print()
      local fix_result = core.health_check(true)
      printer.restore()

      -- Verify the fix was successful
      assert.is_true(fix_result)

      -- Verify the broken symlink was removed
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua"))
    end)

    it("should handle init followed by health_check", function()
      -- Setup test fixture with a plugin file in plugins directory
      local cfg = utils.setup_fixture({
        plugins = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" }
        }
      })

      -- Helper function to check if a plugin is in a list
      local function contains(list, item)
        for _, value in ipairs(list) do
          if value == item then return true end
        end
        return false
      end

      utils.run_workflow({
        {
          description = "Initialize the plugin system",
          action = function()
            return core.init()
          end,
          verify = function(result)
            -- Verify the result
            assert.is_true(result, "Init operation should succeed")

            -- Verify using core API functions
            local available = core.get_available_plugins()
            local enabled = core.get_enabled_plugins()

            assert.equals(1, #available, "Should have 1 available plugin")
            assert.equals(1, #enabled, "Should have 1 enabled plugin")

            -- Verify the plugin exists in both directories
            assert.is_true(contains(available, "plugin1.lua"),
              "plugin1.lua should be in available plugins")
            assert.is_true(contains(enabled, "plugin1.lua"),
              "plugin1.lua should be in enabled plugins")

            -- Verify the file content and symlink through the file system
            assert.is_true(utils.fs_mock.directory_exists(cfg.available_dir),
              "Available directory should exist")
            assert.equals("-- Plugin 1 content",
              utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"),
              "Plugin file should have correct content")
            assert.equals(cfg.available_dir .. "/plugin1.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"),
              "Plugin should be symlinked from plugins dir to available dir")
          end
        },
        {
          description = "Run health_check with no issues",
          action = function()
            return core.health_check(false)
          end,
          verify = function(result)
            -- Verify health check passes when no issues
            assert.is_true(result, "Health check should pass when no issues")

            -- Verify plugins are still in the correct state
            local enabled = core.get_enabled_plugins()
            assert.equals(1, #enabled, "Should still have 1 enabled plugin")
            assert.is_true(contains(enabled, "plugin1.lua"),
              "plugin1.lua should still be enabled")
          end
        },
        {
          description = "Create a broken symlink",
          action = function()
            utils.fs_mock.set_symlink("/non/existent/path.lua",
              cfg.plugins_dir .. "/broken.lua")
            return true
          end,
          verify = function(result)
            -- Verify the broken symlink exists
            assert.equals("/non/existent/path.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua"),
              "Broken symlink should be created")
          end
        },
        {
          description = "Run health_check with issues",
          action = function()
            return core.health_check(false)
          end,
          verify = function(result)
            -- Verify health check fails with broken symlink
            assert.is_false(result, "Health check should fail with broken symlink")

            -- Verify the broken symlink still exists (since we didn't fix)
            assert.equals("/non/existent/path.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua"),
              "Broken symlink should still exist after check-only health check")
          end
        },
        {
          description = "Run health_check with fix",
          action = function()
            return core.health_check(true)
          end,
          verify = function(result)
            -- Verify health check fix succeeds
            assert.is_true(result, "Health check fix should succeed")

            -- Verify broken symlink was removed
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua"),
              "Broken symlink should be removed after health check fix")

            -- Verify valid plugin is still enabled
            local enabled = core.get_enabled_plugins()
            assert.equals(1, #enabled, "Should still have 1 enabled plugin")
            assert.is_true(contains(enabled, "plugin1.lua"),
              "plugin1.lua should still be enabled")
          end
        }
      })
    end)

    it("should handle disable --all followed by enable for specific plugins", function()
      -- Setup test fixture with plugins already enabled
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" },
          { name = "plugin2.lua", content = "-- Plugin 2 content" },
          { name = "plugin3.lua", content = "-- Plugin 3 content" }
        }
      })

      -- Create symlinks in the plugins directory to simulate enabled plugins
      utils.fs_mock.set_symlink(cfg.available_dir .. "/plugin1.lua",
        cfg.plugins_dir .. "/plugin1.lua")
      utils.fs_mock.set_symlink(cfg.available_dir .. "/plugin2.lua",
        cfg.plugins_dir .. "/plugin2.lua")
      utils.fs_mock.set_symlink(cfg.available_dir .. "/plugin3.lua",
        cfg.plugins_dir .. "/plugin3.lua")

      -- Helper function to check if a plugin is in a list
      local function contains(list, item)
        for _, value in ipairs(list) do
          if value == item then return true end
        end
        return false
      end

      utils.run_workflow({
        {
          description = "Verify initial state - all plugins are enabled",
          action = function()
            local enabled = core.get_enabled_plugins()
            return enabled
          end,
          verify = function(enabled)
            assert.equals(3, #enabled, "Should have 3 enabled plugins initially")
            assert.is_true(contains(enabled, "plugin1.lua"), "plugin1 should be enabled")
            assert.is_true(contains(enabled, "plugin2.lua"), "plugin2 should be enabled")
            assert.is_true(contains(enabled, "plugin3.lua"), "plugin3 should be enabled")
          end
        },
        {
          description = "Disable all plugins",
          action = function()
            return core.disable({}, true) -- empty list + all flag = disable all
          end,
          verify = function(result)
            assert.is_true(result, "Disable all operation should succeed")

            -- Verify using core API functions
            local enabled = core.get_enabled_plugins()
            assert.equals(0, #enabled, "Should have 0 enabled plugins")

            -- Verify symlinks are removed
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"),
              "plugin1 symlink should be removed")
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"),
              "plugin2 symlink should be removed")
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"),
              "plugin3 symlink should be removed")
          end
        },
        {
          description = "Enable specific plugin (plugin2)",
          action = function()
            return core.enable({ "plugin2.lua" }, false)
          end,
          verify = function(result)
            assert.is_true(result, "Enable specific plugin operation should succeed")

            -- Verify using core API functions
            local enabled = core.get_enabled_plugins()
            assert.equals(1, #enabled, "Should have 1 enabled plugin")
            assert.is_true(contains(enabled, "plugin2.lua"), "plugin2 should be enabled")

            -- Verify specific plugins are enabled/disabled via symlinks
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"),
              "plugin1 symlink should still be removed")
            assert.equals(cfg.available_dir .. "/plugin2.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"),
              "plugin2 should be symlinked")
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"),
              "plugin3 symlink should still be removed")
          end
        }
      })
    end)

    it("should handle the full workflow: init -> enable -> disable -> health_check", function()
      -- Setup test fixture with plugin files in plugins directory
      local cfg = utils.setup_fixture({
        plugins = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" },
          { name = "plugin2.lua", content = "-- Plugin 2 content" }
        }
      })

      -- Helper function to check if a plugin is in a list
      local function contains(list, item)
        for _, value in ipairs(list) do
          if value == item then return true end
        end
        return false
      end

      utils.run_workflow({
        {
          description = "Step 1: Initialize the plugin system",
          action = function()
            return core.init()
          end,
          verify = function(result)
            assert.is_true(result, "Init operation should succeed")

            -- Verify directory structure
            assert.is_true(utils.fs_mock.directory_exists(cfg.available_dir),
              "Available directory should exist")

            -- Verify files were moved and symlinked
            assert.equals("-- Plugin 1 content",
              utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"),
              "Plugin1 file should have correct content in available dir")
            assert.equals("-- Plugin 2 content",
              utils.fs_mock.get_file(cfg.available_dir .. "/plugin2.lua"),
              "Plugin2 file should have correct content in available dir")

            -- Verify symlinks were created
            assert.equals(cfg.available_dir .. "/plugin1.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"),
              "Plugin1 should be symlinked from plugins dir to available dir")
            assert.equals(cfg.available_dir .. "/plugin2.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"),
              "Plugin2 should be symlinked from plugins dir to available dir")

            -- Verify using core API
            local available = core.get_available_plugins()
            local enabled = core.get_enabled_plugins()

            assert.equals(2, #available, "Should have 2 available plugins")
            assert.equals(2, #enabled, "Should have 2 enabled plugins")
          end
        },
        {
          description = "Step 2: Add and enable a new plugin",
          action = function()
            -- Add a new plugin to available directory
            utils.fs_mock.set_file(cfg.available_dir .. "/plugin3.lua",
              "-- Plugin 3 content")

            -- Enable the new plugin
            return core.enable({ "plugin3.lua" }, false)
          end,
          verify = function(result)
            assert.is_true(result, "Enable operation should succeed")

            -- Verify the new plugin is enabled via symlink
            assert.equals(cfg.available_dir .. "/plugin3.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"),
              "Plugin3 should be symlinked")

            -- Verify all plugins are enabled
            local enabled = core.get_enabled_plugins()
            assert.equals(3, #enabled, "Should now have 3 enabled plugins")
            assert.is_true(contains(enabled, "plugin1.lua"), "plugin1 should be enabled")
            assert.is_true(contains(enabled, "plugin2.lua"), "plugin2 should be enabled")
            assert.is_true(contains(enabled, "plugin3.lua"), "plugin3 should be enabled")
          end
        },
        {
          description = "Step 3: Disable a specific plugin",
          action = function()
            return core.disable({ "plugin1.lua" }, false)
          end,
          verify = function(result)
            assert.is_true(result, "Disable operation should succeed")

            -- Verify plugin1 is disabled via symlink check
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"),
              "plugin1 symlink should be removed")

            -- Verify other plugins are still enabled
            assert.equals(cfg.available_dir .. "/plugin2.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"),
              "Plugin2 should still be symlinked")
            assert.equals(cfg.available_dir .. "/plugin3.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"),
              "Plugin3 should still be symlinked")

            -- Verify using core API
            local enabled = core.get_enabled_plugins()
            assert.equals(2, #enabled, "Should now have 2 enabled plugins")
            assert.is_false(contains(enabled, "plugin1.lua"), "plugin1 should be disabled")
            assert.is_true(contains(enabled, "plugin2.lua"), "plugin2 should be enabled")
            assert.is_true(contains(enabled, "plugin3.lua"), "plugin3 should be enabled")
          end
        },
        {
          description = "Step 4: Create a broken symlink",
          action = function()
            utils.fs_mock.set_symlink("/non/existent/path.lua",
              cfg.plugins_dir .. "/broken.lua")
            return true
          end,
          verify = function(result)
            -- Verify the broken symlink exists
            assert.equals("/non/existent/path.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua"),
              "Broken symlink should exist")
          end
        },
        {
          description = "Step 5: Run health_check to find issues",
          action = function()
            return core.health_check(false)
          end,
          verify = function(result)
            -- Verify health check fails with broken symlink
            assert.is_false(result, "Health check should fail with broken symlink")

            -- Verify the broken symlink still exists (since we didn't fix)
            assert.equals("/non/existent/path.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua"),
              "Broken symlink should still exist after check-only health check")

            -- Verify other plugins are untouched
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"),
              "plugin1 should still be disabled")
            assert.equals(cfg.available_dir .. "/plugin2.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"),
              "Plugin2 should still be symlinked")
            assert.equals(cfg.available_dir .. "/plugin3.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"),
              "Plugin3 should still be symlinked")
          end
        },
        {
          description = "Step 6: Run health_check with fix",
          action = function()
            return core.health_check(true)
          end,
          verify = function(result)
            -- Verify health check fix succeeds
            assert.is_true(result, "Health check fix should succeed")

            -- Verify broken symlink was removed
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua"),
              "Broken symlink should be removed after health check fix")

            -- Verify other plugins are still in the correct state
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"),
              "plugin1 should still be disabled")
            assert.equals(cfg.available_dir .. "/plugin2.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"),
              "Plugin2 should still be symlinked")
            assert.equals(cfg.available_dir .. "/plugin3.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"),
              "Plugin3 should still be symlinked")

            -- Verify using core API
            local enabled = core.get_enabled_plugins()
            assert.equals(2, #enabled, "Should still have 2 enabled plugins")
            assert.is_false(contains(enabled, "plugin1.lua"), "plugin1 should be disabled")
            assert.is_true(contains(enabled, "plugin2.lua"), "plugin2 should be enabled")
            assert.is_true(contains(enabled, "plugin3.lua"), "plugin3 should be enabled")
          end
        }
      })
    end)

    it("should handle init followed by enable for new plugins", function()
      -- Setup test fixture with a plugin file in plugins directory
      local cfg = utils.setup_fixture({
        plugins = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" }
        }
      })

      -- Helper function to check if a plugin is in a list
      local function contains(list, item)
        for _, value in ipairs(list) do
          if value == item then return true end
        end
        return false
      end

      utils.run_workflow({
        {
          description = "Verify initial state",
          action = function()
            -- Just verify the initial state, return the cfg
            return cfg
          end,
          verify = function(result)
            -- Verify plugin1 exists in plugins dir but available_dir doesn't exist yet
            assert.equals("-- Plugin 1 content",
              utils.fs_mock.get_file(cfg.plugins_dir .. "/plugin1.lua"),
              "Plugin1 file should exist in plugins dir")

            -- The directory will actually exist because setup_fixture creates it
            -- but it should be empty
            local available = core.get_available_plugins()
            assert.equals(0, #available, "No plugins should be available yet")
          end
        },
        {
          description = "Run init",
          action = function()
            return core.init()
          end,
          verify = function(result)
            assert.is_true(result, "Init operation should succeed")

            -- Verify init results - plugin1 moved to available_dir and symlinked back
            assert.equals("-- Plugin 1 content",
              utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"),
              "Plugin1 file should be copied to available dir")
            assert.equals(cfg.available_dir .. "/plugin1.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"),
              "Plugin1 should be symlinked from plugins dir to available dir")

            -- Verify using core API
            local available = core.get_available_plugins()
            local enabled = core.get_enabled_plugins()

            assert.equals(1, #available, "Should have 1 available plugin")
            assert.equals(1, #enabled, "Should have 1 enabled plugin")
            assert.is_true(contains(available, "plugin1.lua"), "plugin1 should be available")
            assert.is_true(contains(enabled, "plugin1.lua"), "plugin1 should be enabled")
          end
        },
        {
          description = "Add a new plugin to available directory",
          action = function()
            utils.fs_mock.set_file(cfg.available_dir .. "/plugin2.lua",
              "-- Plugin 2 content")
            return true
          end,
          verify = function(result)
            -- Verify the file was added
            assert.equals("-- Plugin 2 content",
              utils.fs_mock.get_file(cfg.available_dir .. "/plugin2.lua"),
              "Plugin2 file should be added to available dir")

            -- Verify it's not enabled yet
            assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"),
              "Plugin2 should not be symlinked yet")

            -- Verify using core API
            local available = core.get_available_plugins()
            local enabled = core.get_enabled_plugins()

            assert.equals(2, #available, "Should have 2 available plugins")
            assert.equals(1, #enabled, "Should still have 1 enabled plugin")
            assert.is_true(contains(available, "plugin2.lua"), "plugin2 should be available")
            assert.is_false(contains(enabled, "plugin2.lua"), "plugin2 should not be enabled yet")
          end
        },
        {
          description = "Enable the new plugin",
          action = function()
            return core.enable({ "plugin2.lua" }, false)
          end,
          verify = function(result)
            assert.is_true(result, "Enable operation should succeed")

            -- Verify both plugins are enabled via symlinks
            assert.equals(cfg.available_dir .. "/plugin1.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"),
              "Plugin1 should still be symlinked")
            assert.equals(cfg.available_dir .. "/plugin2.lua",
              utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"),
              "Plugin2 should now be symlinked")

            -- Verify using core API
            local enabled = core.get_enabled_plugins()
            assert.equals(2, #enabled, "Should now have 2 enabled plugins")
            assert.is_true(contains(enabled, "plugin1.lua"), "plugin1 should be enabled")
            assert.is_true(contains(enabled, "plugin2.lua"), "plugin2 should be enabled")
          end
        }
      })
    end)
  end)

  describe("configuration tests", function()
    it("should work with custom config_dir", function()
      -- Setup test fixture with custom config_dir
      local custom_config_dir = "/custom/config"

      -- Setup filesystem mocking manually to ensure proper configuration
      utils.fs_mock.setup()
      utils.fs_mock.reset()

      -- Create custom directories
      local custom_plugins_dir = custom_config_dir .. "/lua/plugins"
      local custom_available_dir = custom_config_dir .. "/lua/plugins-available"

      utils.fs_mock.set_directory(custom_config_dir)
      utils.fs_mock.set_directory(custom_config_dir .. "/lua")
      utils.fs_mock.set_directory(custom_plugins_dir)
      utils.fs_mock.set_directory(custom_available_dir)

      -- Add a plugin file to plugins directory
      utils.fs_mock.set_file(custom_plugins_dir .. "/plugin1.lua", "-- Plugin 1 content")

      -- Configure VLIP to use our custom paths
      core.configure({
        config_dir = custom_config_dir,
        plugins_dir = custom_plugins_dir,
        available_dir = custom_available_dir
      })

      -- Run init
      local init_result = core.init()
      assert.is_true(init_result)

      -- Verify that the plugin was moved to the custom plugins-available directory
      assert.equals("-- Plugin 1 content",
        utils.fs_mock.get_file(custom_available_dir .. "/plugin1.lua"))

      -- Verify that a symlink was created in the custom plugins directory
      assert.equals(custom_available_dir .. "/plugin1.lua",
        utils.fs_mock.get_symlink(custom_plugins_dir .. "/plugin1.lua"))

      -- Add a new plugin to available directory
      utils.fs_mock.set_file(custom_available_dir .. "/plugin2.lua", "-- Plugin 2 content")

      -- Enable the new plugin
      local enable_result = core.enable({ "plugin2.lua" }, false)
      assert.is_true(enable_result)

      -- Verify the plugin was enabled in the custom plugins directory
      assert.equals(custom_available_dir .. "/plugin2.lua",
        utils.fs_mock.get_symlink(custom_plugins_dir .. "/plugin2.lua"))
    end)
  end)
end)

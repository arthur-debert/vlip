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

    it("should handle init followed by health_check", function()
      -- Setup test fixture with a plugin file in plugins directory
      local cfg = utils.setup_fixture({
        plugins = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" }
        }
      })

      -- Verify initial state
      assert.is_false(utils.fs_mock.directory_exists(cfg.available_dir))
      assert.is_nil(utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))

      -- Run init
      local init_result = core.init()
      assert.is_true(init_result)

      -- Verify init results
      assert.is_true(utils.fs_mock.directory_exists(cfg.available_dir))
      assert.equals("-- Plugin 1 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin1.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))

      -- Run health_check with no issues
      local health_result = core.health_check(false)
      assert.is_true(health_result)

      -- Create a broken symlink
      utils.fs_mock.set_symlink(cfg.plugins_dir .. "/broken.lua", "/non/existent/path.lua")

      -- Run health_check with issues
      health_result = core.health_check(false)
      assert.is_false(health_result)

      -- Run health_check with fix
      local health_fix_result = core.health_check(true)
      assert.is_true(health_fix_result)

      -- Verify broken symlink was removed
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua"))
    end)

    it("should handle enable --all followed by disable for specific plugins", function()
      -- Setup test fixture
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" },
          { name = "plugin2.lua", content = "-- Plugin 2 content" },
          { name = "plugin3.lua", content = "-- Plugin 3 content" }
        }
      })

      -- Verify initial state
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))

      -- Enable all plugins
      local enable_result = core.enable({}, true)
      assert.is_true(enable_result)

      -- Verify all plugins are enabled
      assert.equals(cfg.available_dir .. "/plugin1.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.equals(cfg.available_dir .. "/plugin3.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))

      -- Disable specific plugins
      local disable_result = core.disable({ "plugin1.lua", "plugin3.lua" }, false)
      assert.is_true(disable_result)

      -- Verify specific plugins are disabled
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))
    end)

    it("should handle disable --all followed by enable for specific plugins", function()
      -- Setup test fixture with all plugins enabled
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" },
          { name = "plugin2.lua", content = "-- Plugin 2 content" },
          { name = "plugin3.lua", content = "-- Plugin 3 content" }
        }
      })

      -- Create symlinks in the plugins directory to simulate enabled plugins
      utils.fs_mock.set_symlink(cfg.plugins_dir .. "/plugin1.lua", cfg.available_dir .. "/plugin1.lua")
      utils.fs_mock.set_symlink(cfg.plugins_dir .. "/plugin2.lua", cfg.available_dir .. "/plugin2.lua")
      utils.fs_mock.set_symlink(cfg.plugins_dir .. "/plugin3.lua", cfg.available_dir .. "/plugin3.lua")

      -- Verify initial state - all plugins are enabled
      assert.equals(cfg.available_dir .. "/plugin1.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.equals(cfg.available_dir .. "/plugin3.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))

      -- Disable all plugins
      local disable_result = core.disable({}, true)
      assert.is_true(disable_result)

      -- Verify all plugins are disabled
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))

      -- Enable specific plugins
      local enable_result = core.enable({ "plugin2.lua" }, false)
      assert.is_true(enable_result)

      -- Verify specific plugins are enabled
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))
    end)

    it("should handle init followed by enable for new plugins", function()
      -- Setup test fixture with a plugin file in plugins directory
      local cfg = utils.setup_fixture({
        plugins = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" }
        }
      })

      -- Create plugins directory if it doesn't exist
      if not utils.fs_mock.directory_exists(cfg.plugins_dir) then
        utils.fs_mock.set_directory(cfg.plugins_dir)
      end

      -- Verify initial state
      assert.is_false(utils.fs_mock.directory_exists(cfg.available_dir))

      -- Run init
      local init_result = core.init()
      assert.is_true(init_result)

      -- Add a new plugin to available directory
      utils.fs_mock.set_file(cfg.available_dir .. "/plugin2.lua", "-- Plugin 2 content")

      -- Enable the new plugin
      local enable_result = core.enable({ "plugin2.lua" }, false)
      assert.is_true(enable_result)

      -- Verify both plugins are enabled
      assert.equals(cfg.available_dir .. "/plugin1.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
    end)

    it("should handle the full workflow: init -> enable -> disable -> health_check", function()
      -- Setup test fixture with plugin files in plugins directory
      local cfg = utils.setup_fixture({
        plugins = {
          { name = "plugin1.lua", content = "-- Plugin 1 content" },
          { name = "plugin2.lua", content = "-- Plugin 2 content" }
        }
      })

      -- Create plugins directory if it doesn't exist
      if not utils.fs_mock.directory_exists(cfg.plugins_dir) then
        utils.fs_mock.set_directory(cfg.plugins_dir)
      end

      -- Verify initial state
      assert.is_false(utils.fs_mock.directory_exists(cfg.available_dir))

      -- Step 1: Run init
      local init_result = core.init()
      assert.is_true(init_result)

      -- Verify init results
      assert.is_true(utils.fs_mock.directory_exists(cfg.available_dir))
      assert.equals("-- Plugin 1 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))
      assert.equals("-- Plugin 2 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin2.lua"))
      assert.equals(cfg.available_dir .. "/plugin1.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))

      -- Add a new plugin to available directory
      utils.fs_mock.set_file(cfg.available_dir .. "/plugin3.lua", "-- Plugin 3 content")

      -- Step 2: Enable the new plugin
      local enable_result = core.enable({ "plugin3.lua" }, false)
      assert.is_true(enable_result)

      -- Verify all plugins are enabled
      assert.equals(cfg.available_dir .. "/plugin1.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.equals(cfg.available_dir .. "/plugin3.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))

      -- Step 3: Disable some plugins
      local disable_result = core.disable({ "plugin1.lua" }, false)
      assert.is_true(disable_result)

      -- Verify plugin1 is disabled
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.equals(cfg.available_dir .. "/plugin3.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))

      -- First run health_check with no issues (should return true)
      local health_result = core.health_check(false)
      assert.is_true(health_result)

      -- Create a broken symlink
      utils.fs_mock.set_symlink(cfg.plugins_dir .. "/broken.lua", "/non/existent/path.lua")

      -- Step 4: Run health_check with issues (should return false)
      health_result = core.health_check(false)
      assert.is_false(health_result)

      -- Run health_check with fix
      local health_fix_result = core.health_check(true)
      assert.is_true(health_fix_result)

      -- Verify broken symlink was removed
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken.lua"))

      -- Verify other plugins are still in the correct state
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      assert.equals(cfg.available_dir .. "/plugin3.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin3.lua"))
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

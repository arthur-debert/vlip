-- Tests for path handling in VLIP
-- Run with: busted spec/vlip_path_handling_spec.lua

-- luacheck: globals io os

local utils = require("spec.utils")

describe("VLIP path handling", function()
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

  describe("paths with special characters", function()
    it("should handle paths with spaces", function()
      -- Setup test fixture with a plugin name containing spaces
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin with spaces", content = "-- Plugin with spaces content" }
        }
      })

      -- Manually set up the symlink using fs_mock API
      utils.fs_mock.set_symlink(cfg.available_dir .. "/plugin with spaces.lua",
        cfg.plugins_dir .. "/plugin with spaces.lua")

      -- Capture print output
      local printer = utils.capture_print()

      -- Run health check to verify the symlink is valid
      local result = core.health_check(false)

      -- Restore print
      printer.restore()

      -- Verify health check passes
      assert.is_true(result)

      -- Verify the symlink exists and points to the correct target
      assert.equals(cfg.available_dir .. "/plugin with spaces.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin with spaces.lua"))

      -- Now try to disable it
      printer = utils.capture_print()
      result = core.disable({ "plugin with spaces" }, false)
      printer.restore()

      -- Verify the plugin was disabled
      assert.is_true(result)
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin with spaces.lua"))
    end)

    it("should handle paths with non-ASCII characters", function()
      -- Setup test fixture with a plugin name containing non-ASCII characters
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin_üñíçødé", content = "-- Plugin with unicode content" }
        }
      })

      -- Manually set up the symlink using fs_mock API
      utils.fs_mock.set_symlink(cfg.available_dir .. "/plugin_üñíçødé.lua",
        cfg.plugins_dir .. "/plugin_üñíçødé.lua")

      -- Capture print output
      local printer = utils.capture_print()

      -- Run health check to verify the symlink is valid
      local result = core.health_check(false)

      -- Restore print
      printer.restore()

      -- Verify health check passes
      assert.is_true(result)

      -- Verify the symlink exists and points to the correct target
      assert.equals(cfg.available_dir .. "/plugin_üñíçødé.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin_üñíçødé.lua"))
    end)

    it("should handle paths with special characters", function()
      -- Setup test fixture with a plugin name containing special characters
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = "plugin-with-dashes",      content = "-- Plugin with dashes content" },
          { name = "plugin_with_underscores", content = "-- Plugin with underscores content" },
          { name = "plugin.with.dots",        content = "-- Plugin with dots content" }
        }
      })

      -- Manually set up the symlinks using fs_mock API
      utils.fs_mock.set_symlink(cfg.available_dir .. "/plugin-with-dashes.lua",
        cfg.plugins_dir .. "/plugin-with-dashes.lua")
      utils.fs_mock.set_symlink(cfg.available_dir .. "/plugin_with_underscores.lua",
        cfg.plugins_dir .. "/plugin_with_underscores.lua")
      utils.fs_mock.set_symlink(cfg.available_dir .. "/plugin.with.dots.lua",
        cfg.plugins_dir .. "/plugin.with.dots.lua")

      -- Capture print output
      local printer = utils.capture_print()

      -- Run health check to verify the symlinks are valid
      local result = core.health_check(false)

      -- Restore print
      printer.restore()

      -- Verify health check passes
      assert.is_true(result)

      -- Verify the symlinks exist and point to the correct targets
      assert.equals(cfg.available_dir .. "/plugin-with-dashes.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin-with-dashes.lua"))
      assert.equals(cfg.available_dir .. "/plugin_with_underscores.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin_with_underscores.lua"))
      assert.equals(cfg.available_dir .. "/plugin.with.dots.lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin.with.dots.lua"))
    end)

    it("should handle paths with quotes and backslashes", function()
      -- Setup test fixture with a plugin name containing quotes and backslashes
      -- Note: In a real filesystem, these would be problematic, but our mock allows it for testing
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = [[plugin\'with\'quotes]],      content = "-- Plugin with quotes content" },
          { name = [[plugin\\with\\backslashes]], content = "-- Plugin with backslashes content" }
        }
      })

      print("Available dir: " .. cfg.available_dir)
      print("Plugin path quotes: " .. cfg.available_dir .. [[/plugin\'with\'quotes.lua]])
      print("Plugin path backslashes: " .. cfg.available_dir .. [[/plugin\\with\\backslashes.lua]])

      -- Manually set up the symlinks using fs_mock API
      utils.fs_mock.set_symlink(cfg.available_dir .. [[/plugin\'with\'quotes.lua]],
        cfg.plugins_dir .. [[/plugin\'with\'quotes.lua]])
      utils.fs_mock.set_symlink(cfg.available_dir .. [[/plugin\\with\\backslashes.lua]],
        cfg.plugins_dir .. [[/plugin\\with\\backslashes.lua]])

      -- Check if the symlinks were actually created
      print("Symlink quotes exists: " ..
        tostring(utils.fs_mock.get_symlink(cfg.plugins_dir .. [[/plugin\'with\'quotes.lua]]) ~= nil))
      print("Symlink backslashes exists: " ..
        tostring(utils.fs_mock.get_symlink(cfg.plugins_dir .. [[/plugin\\with\\backslashes.lua]]) ~= nil))

      -- Capture print output
      local printer = utils.capture_print()

      -- Run health check to verify the symlinks are valid
      local result = core.health_check(false)

      -- Restore print
      local output = printer.output
      printer.restore()

      print("Health check result: " .. tostring(result))
      print("Health check output:")
      for _, line in ipairs(output) do
        print("  " .. line)
      end

      -- Verify health check passes
      assert.is_true(result)

      -- Verify the symlinks exist and point to the correct targets
      local symlink_quotes = utils.fs_mock.get_symlink(cfg.plugins_dir .. [[/plugin\'with\'quotes.lua]])
      local symlink_backslashes = utils.fs_mock.get_symlink(cfg.plugins_dir .. [[/plugin\\with\\backslashes.lua]])

      print("Symlink quotes: " .. tostring(symlink_quotes))
      print("Symlink backslashes: " .. tostring(symlink_backslashes))
      print("Expected quotes: " .. cfg.available_dir .. [[/plugin\'with\'quotes.lua]])
      print("Expected backslashes: " .. cfg.available_dir .. [[/plugin\\with\\backslashes.lua]])

      assert.equals(cfg.available_dir .. [[/plugin\'with\'quotes.lua]], symlink_quotes)
      assert.equals(cfg.available_dir .. [[/plugin\\with\\backslashes.lua]], symlink_backslashes)
    end)
  end)

  describe("very long paths", function()
    it("should handle paths approaching OS limits", function()
      -- Create a very long plugin name (255 characters)
      local long_name = string.rep("a", 245) -- 245 + ".lua" = 249 characters

      -- Setup test fixture with a plugin with a very long name
      local cfg = utils.setup_fixture({
        plugins_available = {
          { name = long_name, content = "-- Plugin with very long name content" }
        }
      })

      -- Manually set up the symlink using fs_mock API
      utils.fs_mock.set_symlink(cfg.available_dir .. "/" .. long_name .. ".lua",
        cfg.plugins_dir .. "/" .. long_name .. ".lua")

      -- Capture print output
      local printer = utils.capture_print()

      -- Run health check to verify the symlink is valid
      local result = core.health_check(false)

      -- Restore print
      printer.restore()

      -- Verify health check passes
      assert.is_true(result)

      -- Verify the symlink exists and points to the correct target
      assert.equals(cfg.available_dir .. "/" .. long_name .. ".lua",
        utils.fs_mock.get_symlink(cfg.plugins_dir .. "/" .. long_name .. ".lua"))
    end)

    it("should handle deeply nested directory structures", function()
      -- Create a deeply nested directory structure
      local deep_dir = "/mock/config/lua/plugins-available"
      for i = 1, 10 do
        deep_dir = deep_dir .. "/level" .. i
      end

      -- Setup test fixture
      local cfg = utils.setup_fixture({})

      -- Create the deeply nested directories
      utils.fs_mock.set_directory(deep_dir)

      -- Create a plugin file in the deeply nested directory
      local plugin_path = deep_dir .. "/deep_plugin.lua"
      utils.fs_mock.set_file(plugin_path, "-- Deeply nested plugin content")

      -- Create a symlink to the deeply nested plugin
      local link_path = cfg.plugins_dir .. "/deep_plugin.lua"
      utils.fs_mock.set_symlink(plugin_path, link_path)

      -- Capture print output
      local printer = utils.capture_print()

      -- Run health check to verify the symlink is valid
      local result = core.health_check(false)

      -- Restore print
      printer.restore()

      -- Verify health check fails (since the symlink points outside plugins-available)
      assert.is_false(result)

      -- Verify the symlink exists and points to the correct target
      assert.equals(plugin_path, utils.fs_mock.get_symlink(link_path))
    end)
  end)
end)

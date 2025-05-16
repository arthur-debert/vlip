-- Tests for disable command edge cases
local utils = require("spec.utils")

describe("vlip disable command - edge cases", function()
  local core

  setup(function()
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
  end)

  after_each(function()
    utils.teardown_fixture()
  end)

  it("should disable plugins that are symlinks but point to non-existent targets", function()
    -- Setup test fixture with a plugin that points to a non-existent target
    local cfg = utils.setup_fixture({
      plugins = {
        { name = "broken_plugin", is_link = true, links_to = "/non/existent/path/plugin.lua" }
      }
    })

    -- Verify the symlink was created correctly
    assert.is_not_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/broken_plugin.lua"))

    -- Capture print output
    local printer = utils.capture_print()

    -- Call the function
    core.disable({ "broken_plugin" }, false)

    -- Restore print
    printer.restore()

    -- Verify output message was correct
    assert.equals("Disabled plugin: broken_plugin.lua", printer.output[1])

    -- Create a hard file path that should have been disabled - not checking for nil
    local disabled_path = cfg.plugins_dir .. "/broken_plugin.lua"
    -- Verify rm command would have been executed on this path
    assert.is_true(utils.fs_mock.file_was_removed(disabled_path))
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
    core.disable({ "regular_file" }, false)

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
        { name = "plugin-with-dashes",      content = "-- Plugin with dashes" },
        { name = "plugin_with_underscores", content = "-- Plugin with underscores" },
        { name = "plugin.with.dots",        content = "-- Plugin with dots" },
        { name = "plugin with spaces",      content = "-- Plugin with spaces" }
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
    core.disable({ "plugin-with-dashes", "plugin_with_underscores",
      "plugin.with.dots", "plugin with spaces" }, false)

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
    core.enable({ "plugin1" }, false)

    -- Verify that the plugin was enabled
    assert.equals(cfg.available_dir .. "/plugin1.lua",
      utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))

    -- Capture print output
    local printer = utils.capture_print()

    -- Now disable the plugin
    core.disable({ "plugin1" }, false)

    -- Restore print
    printer.restore()

    -- Verify that the symlink was removed
    assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))

    -- Verify output
    assert.equals("Disabled plugin: plugin1.lua", printer.output[1])
  end)
end)

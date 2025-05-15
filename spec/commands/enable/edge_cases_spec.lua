-- Tests for enable command edge cases
local utils = require("spec.utils")

describe("vlip enable command - edge cases", function()
  local core
  
  setup(function()
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
  end)
  
  after_each(function()
    utils.teardown_fixture()
  end)
  
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
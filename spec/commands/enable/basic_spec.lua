-- Tests for basic enable command functionality
local utils = require("spec.utils")

describe("vlip enable command - basic functionality", function()
  local core
  
  setup(function()
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
  end)
  
  after_each(function()
    utils.teardown_fixture()
  end)
  
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
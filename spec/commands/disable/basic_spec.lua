-- Tests for basic disable command functionality
local utils = require("spec.utils")

describe("vlip disable command - basic functionality", function()
  local core
  
  setup(function()
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
  end)
  
  after_each(function()
    utils.teardown_fixture()
  end)
  
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
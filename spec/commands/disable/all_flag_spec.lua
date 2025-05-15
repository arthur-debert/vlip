-- Tests for disable command with --all flag
local utils = require("spec.utils")

describe("vlip disable command - --all flag", function()
  local core
  
  setup(function()
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
  end)
  
  after_each(function()
    utils.teardown_fixture()
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

  it("should handle --all flag with no enabled plugins", function()
    -- Setup test fixture with no enabled plugins
    utils.setup_fixture({
      plugins_available = {
        { name = "plugin1", content = "-- Plugin 1 content" }
      }
    })
    
    -- Capture print output
    local printer = utils.capture_print()
    
    -- Call the function
    core.disable({}, true)
    
    -- Restore print
    printer.restore()
    
    -- Verify no output since no plugins were disabled
    assert.equals(0, #printer.output)
  end)
end)
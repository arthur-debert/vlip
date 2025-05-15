-- Tests for enable command with --all flag
local utils = require("spec.utils")

describe("vlip enable command - --all flag", function()
  local core
  
  setup(function()
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
  end)
  
  after_each(function()
    utils.teardown_fixture()
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

  it("should handle --all flag with no available plugins", function()
    -- Setup test fixture with no plugins
    utils.setup_fixture({})
    
    -- Capture print output
    local printer = utils.capture_print()
    
    -- Call the function
    core.enable({}, true)
    
    -- Restore print
    printer.restore()
    
    -- Verify no output since no plugins were enabled
    assert.equals(0, #printer.output)
  end)
end)
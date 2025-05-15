-- Test utilities for VLIP
local fs_mock = require("spec.utils.fs_mock")

local test_utils = {}

-- Default configuration
local default_config = {
  config_dir = "/mock/config",
  plugins_dir = "/mock/config/lua/plugins",
  available_dir = "/mock/config/lua/plugins-available"
}

-- Setup a test fixture with the given plugin configuration
-- @param config Table with configuration options:
--   - plugins: Table of plugins in the plugins directory
--   - plugins_available: Table of plugins in the plugins-available directory
--   - config_dir: (optional) Custom config directory path
--   - plugins_dir: (optional) Custom plugins directory path
--   - available_dir: (optional) Custom plugins-available directory path
-- Each plugin entry should be a table with:
--   - name: Plugin name (with or without .lua extension)
--   - content: (optional) Plugin file content
--   - is_link: (optional) Whether the plugin is a symlink
--   - links_to: (optional) Path the symlink points to
function test_utils.setup_fixture(config)
  -- Setup filesystem mocking
  fs_mock.setup()
  fs_mock.reset()
  
  -- Get configuration
  local cfg = {
    config_dir = config.config_dir or default_config.config_dir,
    plugins_dir = config.plugins_dir or default_config.plugins_dir,
    available_dir = config.available_dir or default_config.available_dir
  }
  
  -- Create base directories
  fs_mock.set_directory(cfg.config_dir)
  fs_mock.set_directory(cfg.config_dir .. "/lua")
  fs_mock.set_directory(cfg.plugins_dir)
  fs_mock.set_directory(cfg.available_dir)
  
  -- Setup plugins in plugins-available
  if config.plugins_available then
    for _, plugin in ipairs(config.plugins_available) do
      local name = plugin.name
      if not name:match("%.lua$") then
        name = name .. ".lua"
      end
      
      local path = cfg.available_dir .. "/" .. name
      
      if plugin.is_link then
        fs_mock.set_symlink(plugin.links_to, path)
      else
        fs_mock.set_file(path, plugin.content or ("-- " .. name))
      end
    end
  end
  
  -- Setup plugins in plugins
  if config.plugins then
    for _, plugin in ipairs(config.plugins) do
      local name = plugin.name
      if not name:match("%.lua$") then
        name = name .. ".lua"
      end
      
      local path = cfg.plugins_dir .. "/" .. name
      
      if plugin.is_link then
        fs_mock.set_symlink(plugin.links_to, path)
      else
        fs_mock.set_file(path, plugin.content or ("-- " .. name))
      end
    end
  end
  
  -- Configure VLIP to use our mock paths
  local core = require("vlip.core")
  core.configure(cfg)
  
  return cfg
end

-- Capture print output
function test_utils.capture_print()
  local output = {}
  local original_print = print
  
  _G.print = function(msg)
    table.insert(output, msg)
  end
  
  return {
    output = output,
    restore = function()
      _G.print = original_print
    end
  }
end

-- Teardown the test fixture
function test_utils.teardown_fixture()
  fs_mock.teardown()
end

return test_utils
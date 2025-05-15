-- Test utilities for VLIP
local fs_mock = require("spec.utils.fs_mock")
local test_utils = {}

-- Add all possible package paths
package.path = table.concat({
  "./?.lua",
  "./?/init.lua",
  "./lua/?.lua",
  "./lua/?/init.lua",
  "./.luarocks/share/lua/5.1/?.lua",
  "./.luarocks/share/lua/5.1/?/init.lua",
  "/home/runner/.luarocks/share/lua/5.1/?.lua",
  "/home/runner/.luarocks/share/lua/5.1/?/init.lua",
  package.path
}, ";")

-- Load required modules
local path = require("path")
local core = require("vlip.core")

-- Set path module in core for testing
core._set_path(path)

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

      local plugin_path = cfg.available_dir .. "/" .. name

      if plugin.is_link then
        fs_mock.set_symlink(plugin.links_to, plugin_path)
      else
        fs_mock.set_file(plugin_path, plugin.content or ("-- " .. name))
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

      local plugin_path = cfg.plugins_dir .. "/" .. name

      if plugin.is_link then
        fs_mock.set_symlink(plugin.links_to, plugin_path)
      else
        fs_mock.set_file(plugin_path, plugin.content or ("-- " .. name))
      end
    end
  end

  -- Configure VLIP to use our mock paths
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

-- Helper function for multi-step workflow tests
-- @param steps Table of steps, each with:
--   - action: Function to execute for this step
--   - description: (optional) Description of the step
--   - verify: (optional) Function to verify state after the step
--   - debug: (optional) Boolean to enable debug printing after this step
function test_utils.run_workflow(steps, debug_mode)
  -- Enable debug mode if requested
  if debug_mode then
    fs_mock.enable_debug()
  end

  -- Run each step in sequence
  for i, step in ipairs(steps) do
    if step.description then
      print("STEP " .. i .. ": " .. step.description)
    end

    local result
    local error_msg

    -- Execute the action with error handling
    local status, action_result = pcall(function()
      return step.action()
    end)

    if status then
      result = action_result
    else
      error_msg = action_result
      result = false
    end

    -- Verify step result
    if error_msg then
      assert(false, "Step " .. i .. " failed with error: " .. tostring(error_msg))
    end

    -- Optional verification after the step
    if step.verify then
      local verify_status, verify_error = pcall(step.verify, result)
      if not verify_status then
        local error_str = type(verify_error) == "table"
            and "table (use debug mode to see details)"
            or tostring(verify_error)
        assert(false, "Verification for step " .. i .. " failed: " .. error_str)
      end
    end

    -- Debug dump of state if requested
    if debug_mode or step.debug then
      print("State after step " .. i .. ":")
      fs_mock.dump_state()
    end
  end

  -- Disable debug mode if it was enabled
  if debug_mode then
    fs_mock.disable_debug()
  end
end

return test_utils

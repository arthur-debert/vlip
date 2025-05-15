# VLIP Test Suite

This directory contains tests and testing utilities for VLIP.

## Test Utilities

All test utilities are located in the `spec/utils` directory and can be imported with a single require:

```lua
local utils = require("spec.utils")
```

### Available Utilities

The utils module provides the following functionality:

1. **Filesystem Mocking**
   - `utils.fs_mock.setup()` - Set up filesystem mocking
   - `utils.fs_mock.teardown()` - Tear down filesystem mocking
   - `utils.fs_mock.reset()` - Reset the mock filesystem state
   - `utils.fs_mock.set_file(path, content)` - Create a mock file
   - `utils.fs_mock.set_directory(path)` - Create a mock directory
   - `utils.fs_mock.set_symlink(src, dst)` - Create a mock symlink
   - `utils.fs_mock.get_file(path)` - Get mock file content
   - `utils.fs_mock.get_symlink(path)` - Get mock symlink target
   - `utils.fs_mock.file_exists(path)` - Check if a mock file exists
   - `utils.fs_mock.directory_exists(path)` - Check if a mock directory exists
   - `utils.fs_mock.enable_debug()` - Enable detailed debug logging
   - `utils.fs_mock.disable_debug()` - Disable debug logging
   - `utils.fs_mock.dump_state()` - Print current mock filesystem state

2. **Test Fixtures**
   - `utils.setup_fixture(config)` - Set up a test fixture with plugins
   - `utils.teardown_fixture()` - Tear down a test fixture
   - `utils.capture_print()` - Capture print output for testing
   - `utils.run_workflow(steps, debug_mode)` - Run a multi-step workflow test

## Writing Tests

### Basic Test Structure

```lua
local utils = require("spec.utils")

describe("My VLIP test", function()
  local core
  
  setup(function()
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
  end)
  
  after_each(function()
    utils.teardown_fixture()
  end)
  
  it("should do something", function()
    -- Set up test fixture
    utils.setup_fixture({
      plugins_available = {
        { name = "plugin1", content = "-- Plugin 1 content" },
        { name = "plugin2", content = "-- Plugin 2 content" }
      },
      plugins = {
        { name = "plugin1", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" }
      }
    })
    
    -- Test code here
    -- ...
    
    -- Assert results
    -- ...
  end)
end)
```

### Setting Up Test Fixtures

The `setup_fixture` function accepts a table with the following structure:

```lua
{
  -- Plugins in the plugins-available directory
  plugins_available = {
    { 
      name = "plugin1",                    -- Plugin name (with or without .lua extension)
      content = "-- Plugin 1 content",     -- Optional: Plugin file content
      is_link = false,                     -- Optional: Whether the plugin is a symlink
      links_to = nil                       -- Optional: Path the symlink points to
    },
    -- More plugins...
  },
  
  -- Plugins in the plugins directory
  plugins = {
    {
      name = "plugin2",
      is_link = true,                      -- This is a symlink
      links_to = "/path/to/target"         -- Path the symlink points to
    },
    -- More plugins...
  },
  
  -- Optional custom paths
  config_dir = "/custom/path",             -- Custom config directory path
  plugins_dir = "/custom/plugins",         -- Custom plugins directory path
  available_dir = "/custom/available"      -- Custom plugins-available directory path
}
```

### Capturing Print Output

To test functions that print output:

```lua
-- Capture print output
local printer = utils.capture_print()

-- Call function that prints
core.list_available()

-- Restore print
printer.restore()

-- Verify output
assert.equals("Available plugins:", printer.output[1])
```

### Debugging Filesystem Operations

For tests with complex filesystem interactions, use the enhanced debugging features:

```lua
-- Enable debug mode to see detailed filesystem operations
utils.fs_mock.enable_debug()

-- Run your test operations
core.init()
core.enable({"plugin1"}, false)

-- Print the current state of the mock filesystem
utils.fs_mock.dump_state()

-- Disable debug mode when done
utils.fs_mock.disable_debug()
```

Debug output can also be triggered with the VLIP_DEBUG environment variable:

```lua
if os.getenv("VLIP_DEBUG") then
  utils.fs_mock.dump_state()
end
```

### Multi-Step Workflow Testing

The workflow helper is designed for testing complex interactions that require multiple sequential operations. It provides several key benefits:

1. **Clear Step Structure**: Each test step is isolated with its own action and verification, making the test flow easy to understand.
2. **Robust Error Handling**: If a step fails, you get precise information about which step failed and why.
3. **Step-by-Step Verification**: Verify the state after each operation rather than only at the end of a complex sequence.
4. **Enhanced Debugging**: When issues occur, the helper provides clear step-by-step output showing the state between operations.
5. **Test Reliability**: Using the workflow helper significantly reduces flaky tests by ensuring each step completes successfully before moving to the next.

Example usage:

```lua
-- Setup initial test fixture
local cfg = utils.setup_fixture({
  plugins = {
    { name = "plugin1.lua", content = "-- Plugin 1 content" }
  }
})

-- Define and run a multi-step workflow
utils.run_workflow({
  {
    description = "Initialize the plugin system",
    action = function()
      return core.init()
    end,
    verify = function(result)
      assert.is_true(result)
      
      -- Verify state using core API functions
      local available = core.get_available_plugins()
      assert.equals(1, #available)
    end
  },
  {
    description = "Enable a new plugin",
    action = function()
      -- First add a new plugin to available
      utils.fs_mock.set_file(cfg.available_dir .. "/plugin2.lua", "-- Content")
      
      -- Then enable it
      return core.enable({ "plugin2.lua" }, false)
    end,
    verify = function(result)
      assert.is_true(result)
      
      -- Verify using core API
      local enabled = core.get_enabled_plugins()
      assert.equals(2, #enabled)
    end,
    debug = true  -- This step will dump state even without debug_mode
  }
}, false)  -- Set to true to enable debugging for all steps
```

Each step has:
- `description`: Optional description of the step
- `action`: Function to execute for this step (required)
- `verify`: Function to verify the state after the step
- `debug`: Boolean to enable state dumping for this specific step

## Running Tests

Run all tests:

```bash
busted spec
```

Run a specific test file:

```bash
busted spec/your_test_file.lua
```

## Example Tests

See these files for examples:

- `spec/fs_mock_spec.lua` - Tests for the filesystem mocking functionality
- `spec/test_enhanced_fs_mock_spec.lua` - Tests for enhanced fs_mock functionality
- `spec/vlip_fixture_example_spec.lua` - Example tests using the fixture utilities
- `spec/vlip_workflow_helper_example_spec.lua` - Example of multi-step workflow testing
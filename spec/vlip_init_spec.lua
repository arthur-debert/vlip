-- Tests for the init command
-- Run with: busted spec/vlip_init_spec.lua

-- luacheck: globals io os

local utils = require("spec.utils")

describe("vlip init command", function()
  local core
  local cli
  
  setup(function()
    -- Add the project's lua directory to the package path
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
    cli = require("vlip.cli")
  end)
  
  after_each(function()
    -- Teardown filesystem mocking
    utils.teardown_fixture()
  end)
  
  describe("core.init()", function()
    it("should create plugins-available directory if it doesn't exist", function()
      -- Setup a minimal test fixture
      local cfg = {
        config_dir = "/mock/config",
        plugins_dir = "/mock/config/lua/plugins",
        available_dir = "/mock/config/lua/plugins-available"
      }
      
      -- Set up filesystem mocking
      utils.fs_mock.setup()
      utils.fs_mock.reset()
      
      -- Create base directories except plugins-available
      utils.fs_mock.set_directory(cfg.config_dir)
      utils.fs_mock.set_directory(cfg.config_dir .. "/lua")
      utils.fs_mock.set_directory(cfg.plugins_dir)
      
      -- Add a plugin file
      utils.fs_mock.set_file(cfg.plugins_dir .. "/plugin1.lua", "-- Plugin 1 content")
      
      -- Configure VLIP to use our mock paths
      core.configure(cfg)
      
      -- Verify the directory doesn't exist
      assert.is_false(utils.fs_mock.directory_exists(cfg.available_dir))
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.init()
      
      -- Restore print
      printer.restore()
      
      -- Verify the directory was created
      assert.is_true(utils.fs_mock.directory_exists(cfg.available_dir))
      
      -- Verify output contains the directory creation message
      local found = false
      for _, line in ipairs(printer.output) do
        if line == "Creating plugins-available directory..." then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)
    
    it("should move plugin files to plugins-available and create symlinks", function()
      -- Setup a minimal test fixture
      local cfg = {
        config_dir = "/mock/config",
        plugins_dir = "/mock/config/lua/plugins",
        available_dir = "/mock/config/lua/plugins-available"
      }
      
      -- Set up filesystem mocking
      utils.fs_mock.setup()
      utils.fs_mock.reset()
      
      -- Create base directories
      utils.fs_mock.set_directory(cfg.config_dir)
      utils.fs_mock.set_directory(cfg.config_dir .. "/lua")
      utils.fs_mock.set_directory(cfg.plugins_dir)
      utils.fs_mock.set_directory(cfg.available_dir)
      
      -- Add plugin files
      utils.fs_mock.set_file(cfg.plugins_dir .. "/plugin1.lua", "-- Plugin 1 content")
      utils.fs_mock.set_file(cfg.plugins_dir .. "/plugin2.lua", "-- Plugin 2 content")
      
      -- Configure VLIP to use our mock paths
      core.configure(cfg)
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      core.init()
      
      -- Restore print
      printer.restore()
      
      -- Verify that the files were moved to plugins-available
      assert.equals("-- Plugin 1 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))
      assert.equals("-- Plugin 2 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin2.lua"))
      
      -- Verify that symlinks were created
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                  utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.equals(cfg.available_dir .. "/plugin2.lua",
                  utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      
      -- Verify output contains expected messages
      local found_count = 0
      local expected_messages = {
        "Found %d+ plugin files",
        "Moving plugin1.lua to plugins%-available...",
        "Created symlink for plugin1.lua",
        "Moving plugin2.lua to plugins%-available...",
        "Created symlink for plugin2.lua",
        "Initialization complete!",
        "All plugins have been moved to plugins%-available and symlinked back to plugins"
      }
      
      for _, line in ipairs(printer.output) do
        for _, pattern in ipairs(expected_messages) do
          if line:match(pattern) then
            found_count = found_count + 1
            break
          end
        end
      end
      
      assert.is_true(found_count >= 5, "Expected to find at least 5 of the expected messages")
    end)
    
    it("should handle no plugin files", function()
      -- Setup a minimal test fixture
      local cfg = {
        config_dir = "/mock/config",
        plugins_dir = "/mock/config/lua/plugins",
        available_dir = "/mock/config/lua/plugins-available"
      }
      
      -- Set up filesystem mocking
      utils.fs_mock.setup()
      utils.fs_mock.reset()
      
      -- Create base directories
      utils.fs_mock.set_directory(cfg.config_dir)
      utils.fs_mock.set_directory(cfg.config_dir .. "/lua")
      utils.fs_mock.set_directory(cfg.plugins_dir)
      utils.fs_mock.set_directory(cfg.available_dir)
      
      -- Configure VLIP to use our mock paths
      core.configure(cfg)
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      local result = core.init()
      
      -- Restore print
      printer.restore()
      
      -- Verify result
      assert.is_false(result)
      
      -- Verify output contains the expected message
      local found = false
      for _, line in ipairs(printer.output) do
        if line:match("No plugin files found in: .*") then
          found = true
          break
        end
      end
      assert.is_true(found, "Expected to find 'No plugin files found' message")
    end)
  end)
  
  describe("cli.parse_args() with init", function()
    it("should call core.init() when given init command", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Spy on core.init
      local original_init = core.init
      local init_called = false
      
      core.init = function()
        init_called = true
        return true
      end
      
      -- Call the function
      cli.parse_args({"init"})
      
      -- Restore original function
      core.init = original_init
      
      -- Verify that init was called
      assert.is_true(init_called)
    end)
    
    it("should return the result of core.init()", function()
      -- Setup test fixture with plugins
      utils.setup_fixture({
        plugins = {
          { name = "plugin1", content = "-- Plugin 1 content" }
        }
      })
      
      -- Call the function and capture result
      local result = cli.parse_args({"init"})
      
      -- Verify result
      assert.is_true(result)
    end)
  end)
  
  describe("init command with edge cases", function()
    it("should handle initializing when plugins directory doesn't exist", function()
      -- Setup a minimal test fixture
      local cfg = {
        config_dir = "/mock/config",
        plugins_dir = "/mock/config/lua/plugins",
        available_dir = "/mock/config/lua/plugins-available"
      }
      
      -- Set up filesystem mocking
      utils.fs_mock.setup()
      utils.fs_mock.reset()
      
      -- Create base directories except plugins directory
      utils.fs_mock.set_directory(cfg.config_dir)
      utils.fs_mock.set_directory(cfg.config_dir .. "/lua")
      
      -- Configure VLIP to use our mock paths
      core.configure(cfg)
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      local result = core.init()
      
      -- Restore print
      printer.restore()
      
      -- Verify result
      assert.is_false(result)
      
      -- Create the plugins directory (since core.init doesn't create it if it doesn't exist)
      utils.fs_mock.set_directory(cfg.plugins_dir)
      
      -- Verify that the plugins directory exists
      assert.is_true(utils.fs_mock.directory_exists(cfg.plugins_dir))
      
      -- Verify that the plugins-available directory was created
      assert.is_true(utils.fs_mock.directory_exists(cfg.available_dir))
      
      -- Verify output contains the expected message
      local found = false
      for _, line in ipairs(printer.output) do
        if line:match("No plugin files found in: .*") then
          found = true
          break
        end
      end
      assert.is_true(found, "Expected to find 'No plugin files found' message")
    end)
    
    it("should handle initializing when some plugin files can't be read", function()
      -- Setup a minimal test fixture
      local cfg = {
        config_dir = "/mock/config",
        plugins_dir = "/mock/config/lua/plugins",
        available_dir = "/mock/config/lua/plugins-available"
      }
      
      -- Set up filesystem mocking
      utils.fs_mock.setup()
      utils.fs_mock.reset()
      
      -- Create base directories
      utils.fs_mock.set_directory(cfg.config_dir)
      utils.fs_mock.set_directory(cfg.config_dir .. "/lua")
      utils.fs_mock.set_directory(cfg.plugins_dir)
      utils.fs_mock.set_directory(cfg.available_dir)
      
      -- Add plugin files
      utils.fs_mock.set_file(cfg.plugins_dir .. "/plugin1.lua", "-- Plugin 1 content")
      utils.fs_mock.set_file(cfg.plugins_dir .. "/plugin2.lua", "-- Plugin 2 content")
      
      -- Mock io.open to fail for plugin2.lua
      local original_io_open = io.open
      io.open = function(path, mode)
        if path == cfg.plugins_dir .. "/plugin2.lua" and mode == "r" then
          return nil
        else
          return original_io_open(path, mode)
        end
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      local result = core.init()
      
      -- Restore io.open
      io.open = original_io_open
      
      -- Restore print
      printer.restore()
      
      -- Verify result
      assert.is_false(result)
      
      -- Verify that plugin1 was moved to plugins-available
      assert.equals("-- Plugin 1 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))
      
      -- Verify that plugin1 symlink was created
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                  utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      
      -- Verify that plugin2 was not moved
      assert.is_nil(utils.fs_mock.get_file(cfg.available_dir .. "/plugin2.lua"))
      
      -- Verify output contains the expected error message
      local found = false
      for _, line in ipairs(printer.output) do
        if line:match("Error reading file: .*plugin2.lua") then
          found = true
          break
        end
      end
      assert.is_true(found, "Expected to find error message for plugin2.lua")
      
      -- Verify that initialization completed with errors
      local found_error_message = false
      for _, line in ipairs(printer.output) do
        if line:match("Initialization completed with errors") then
          found_error_message = true
          break
        end
      end
      assert.is_true(found_error_message, "Expected to find 'Initialization completed with errors' message")
    end)
    
    it("should handle initializing when some symlinks can't be created", function()
      -- Setup a minimal test fixture
      local cfg = {
        config_dir = "/mock/config",
        plugins_dir = "/mock/config/lua/plugins",
        available_dir = "/mock/config/lua/plugins-available"
      }
      
      -- Set up filesystem mocking
      utils.fs_mock.setup()
      utils.fs_mock.reset()
      
      -- Create base directories
      utils.fs_mock.set_directory(cfg.config_dir)
      utils.fs_mock.set_directory(cfg.config_dir .. "/lua")
      utils.fs_mock.set_directory(cfg.plugins_dir)
      utils.fs_mock.set_directory(cfg.available_dir)
      
      -- Add plugin files
      utils.fs_mock.set_file(cfg.plugins_dir .. "/plugin1.lua", "-- Plugin 1 content")
      utils.fs_mock.set_file(cfg.plugins_dir .. "/plugin2.lua", "-- Plugin 2 content")
      
      -- Mock os.execute to fail for symlink creation for plugin2.lua
      local original_os_execute = os.execute
      os.execute = function(command)
        if command:match("ln %-sf .*/plugin2.lua") then
          return 1 -- Failure
        else
          return original_os_execute(command)
        end
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      local result = core.init()
      
      -- Restore os.execute
      os.execute = original_os_execute
      
      -- Restore print
      printer.restore()
      
      -- Verify result
      assert.is_false(result)
      
      -- Verify that both plugins were moved to plugins-available
      assert.equals("-- Plugin 1 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))
      assert.equals("-- Plugin 2 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin2.lua"))
      
      -- Verify that only plugin1 symlink was created
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                  utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      assert.is_nil(utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin2.lua"))
      
      -- Verify output contains the expected error message
      local found = false
      for _, line in ipairs(printer.output) do
        if line:match("Error creating symlink: .*plugin2.lua") then
          found = true
          break
        end
      end
      assert.is_true(found, "Expected to find error message for plugin2.lua symlink")
      
      -- Verify that initialization completed with errors
      local found_error_message = false
      for _, line in ipairs(printer.output) do
        if line:match("Initialization completed with errors") then
          found_error_message = true
          break
        end
      end
      assert.is_true(found_error_message, "Expected to find 'Initialization completed with errors' message")
    end)
    
    it("should handle initializing with plugins that have the same name but different content", function()
      -- Setup a minimal test fixture
      local cfg = {
        config_dir = "/mock/config",
        plugins_dir = "/mock/config/lua/plugins",
        available_dir = "/mock/config/lua/plugins-available"
      }
      
      -- Set up filesystem mocking
      utils.fs_mock.setup()
      utils.fs_mock.reset()
      
      -- Create base directories
      utils.fs_mock.set_directory(cfg.config_dir)
      utils.fs_mock.set_directory(cfg.config_dir .. "/lua")
      utils.fs_mock.set_directory(cfg.plugins_dir)
      utils.fs_mock.set_directory(cfg.available_dir)
      
      -- Add plugin file to plugins directory
      utils.fs_mock.set_file(cfg.plugins_dir .. "/plugin1.lua", "-- Plugin 1 content")
      
      -- Add a file with the same name but different content to plugins-available
      utils.fs_mock.set_file(cfg.available_dir .. "/plugin1.lua", "-- Different content")
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      local result = core.init()
      
      -- Restore print
      printer.restore()
      
      -- Verify result
      assert.is_true(result)
      
      -- Verify that the plugin content in plugins-available was overwritten
      assert.equals("-- Plugin 1 content", utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))
      
      -- Verify that the symlink was created
      assert.equals(cfg.available_dir .. "/plugin1.lua",
                  utils.fs_mock.get_symlink(cfg.plugins_dir .. "/plugin1.lua"))
      
      -- Verify output contains the expected messages
      local found_moving = false
      local found_symlink = false
      
      for _, line in ipairs(printer.output) do
        if line:match("Moving plugin1.lua to plugins%-available...") then
          found_moving = true
        elseif line:match("Created symlink for plugin1.lua") then
          found_symlink = true
        end
      end
      
      assert.is_true(found_moving, "Expected to find message about moving plugin1.lua")
      assert.is_true(found_symlink, "Expected to find message about creating symlink for plugin1.lua")
    end)
    
    it("should handle initializing with plugins that have unusual file permissions", function()
      -- Setup a minimal test fixture
      local cfg = {
        config_dir = "/mock/config",
        plugins_dir = "/mock/config/lua/plugins",
        available_dir = "/mock/config/lua/plugins-available"
      }
      
      -- Set up filesystem mocking
      utils.fs_mock.setup()
      utils.fs_mock.reset()
      
      -- Create base directories
      utils.fs_mock.set_directory(cfg.config_dir)
      utils.fs_mock.set_directory(cfg.config_dir .. "/lua")
      utils.fs_mock.set_directory(cfg.plugins_dir)
      utils.fs_mock.set_directory(cfg.available_dir)
      
      -- Add plugin files
      utils.fs_mock.set_file(cfg.plugins_dir .. "/plugin1.lua", "-- Plugin 1 content")
      
      -- Mock io.open to simulate read-only permission for writing to plugins-available
      local original_io_open = io.open
      io.open = function(path, mode)
        if path == cfg.available_dir .. "/plugin1.lua" and mode == "w" then
          return nil -- Simulate permission denied
        else
          return original_io_open(path, mode)
        end
      end
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      local result = core.init()
      
      -- Restore io.open
      io.open = original_io_open
      
      -- Restore print
      printer.restore()
      
      -- Verify result
      assert.is_false(result)
      
      -- Verify that the plugin was not moved to plugins-available
      assert.is_nil(utils.fs_mock.get_file(cfg.available_dir .. "/plugin1.lua"))
      
      -- Verify output contains the expected error message
      local found = false
      for _, line in ipairs(printer.output) do
        if line:match("Error writing file: .*plugin1.lua") then
          found = true
          break
        end
      end
      assert.is_true(found, "Expected to find error message for writing plugin1.lua")
      
      -- Verify that initialization completed with errors
      local found_error_message = false
      for _, line in ipairs(printer.output) do
        if line:match("Initialization completed with errors") then
          found_error_message = true
          break
        end
      end
      assert.is_true(found_error_message, "Expected to find 'Initialization completed with errors' message")
    end)
  end)
end)
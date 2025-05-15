-- Tests for the init command
-- Run with: busted spec/vlip_init_spec.lua

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
end)
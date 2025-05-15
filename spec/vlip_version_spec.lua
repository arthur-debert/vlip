-- Tests for the --version command
-- Run with: busted spec/vlip_version_spec.lua

local utils = require("spec.utils")

describe("vlip --version command", function()
  local cli
  
  setup(function()
    -- Add the project's lua directory to the package path
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    cli = require("vlip.cli")
  end)
  
  after_each(function()
    -- Teardown filesystem mocking
    utils.teardown_fixture()
  end)
  
  describe("cli.parse_args() with --version", function()
    it("should display the version information", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      cli.parse_args({"--version"})
      
      -- Restore print
      printer.restore()
      
      -- Verify output
      assert.equals(1, #printer.output)
      assert.matches("vlip version %d+%.%d+%.%d+", printer.output[1])
    end)
    
    it("should return true when --version command succeeds", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Call the function and capture result
      local result = cli.parse_args({"--version"})
      
      -- Verify result
      assert.is_true(result)
    end)
    
    it("should display the correct version number", function()
      -- Setup test fixture
      utils.setup_fixture({})
      
      -- Get the version from the module
      local version = cli.VERSION
      
      -- Capture print output
      local printer = utils.capture_print()
      
      -- Call the function
      cli.parse_args({"--version"})
      
      -- Restore print
      printer.restore()
      
      -- Verify output contains the correct version
      assert.equals(1, #printer.output)
      assert.equals("vlip version " .. version, printer.output[1]:gsub("\27%[[%d;]+m", ""))
    end)
  end)
end)
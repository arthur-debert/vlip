-- Tests for vlip using busted framework
-- Run with: busted spec/vlip_spec.lua

describe("vlip", function()
  local vlip
  setup(function()
    -- Add the project's lua directory to the package path
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    vlip = require("vlip")
  end)
  
  it("should export core functions", function()
    assert.is_function(vlip.enable)
    assert.is_function(vlip.disable)
    assert.is_function(vlip.health_check)
    assert.is_function(vlip.list_available)
    assert.is_function(vlip.list_enabled)
    assert.is_function(vlip.init)
  end)
  
  it("should have a setup function for Neovim integration", function()
    assert.is_function(vlip.setup)
  end)
  
  -- Add more tests as needed
end)

describe("vlip.core", function()
  local core
  
  setup(function()
    -- Add the project's lua directory to the package path
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
  end)
  
  it("should export plugin management functions", function()
    assert.is_function(core.enable)
    assert.is_function(core.disable)
    assert.is_function(core.health_check)
    assert.is_function(core.list_available)
    assert.is_function(core.list_enabled)
    assert.is_function(core.init)
  end)
  
  -- Add more tests as needed
end)

describe("vlip.cli", function()
  local cli
  
  setup(function()
    -- Add the project's lua directory to the package path
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    cli = require("vlip.cli")
  end)
  
  it("should export CLI functions", function()
    assert.is_function(cli.parse_args)
    assert.is_function(cli.run)
  end)
  
  -- Add more tests as needed
end)
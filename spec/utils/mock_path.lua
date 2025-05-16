-- Mock path module for testing
--
-- This module provides mock implementations of path utilities for testing.
-- It's designed to work consistently across different environments (local and CI).
--
-- IMPORTANT CI COMPATIBILITY NOTE:
-- In CI environments, there's a difference in how Lua resolves module paths.
-- The CI environment includes LuaRocks in the Lua path, which can cause
-- tests to fail with errors like "attempt to concatenate local 'err' (a nil value)"
-- from LuaRocks modules. This happens because the CI environment tries to load
-- actual LuaRocks modules instead of our test mocks.
--
-- To solve this, we:
-- 1. Detect if we're running in a CI environment
-- 2. In CI only: Override the global 'require' function to intercept calls to LuaRocks modules
-- 3. Return our mock instead of letting Lua load the actual LuaRocks modules
--
-- This ensures consistent behavior between local and CI test environments.

local mock_path = {}

-- Track if we're in CI based on environment variable
-- This allows us to apply special handling only in CI environments
local is_ci = os.getenv("CI") == "true"

-- Simple pass-through normalization for testing
function mock_path.normalize(path_str)
  return path_str
end

-- Always return true for existence checks in tests
function mock_path.exists(path_str)
  -- Always return true for testing, but use path_str to avoid luacheck warning
  return path_str ~= nil
end

-- Simple pass-through absolute path conversion for testing
function mock_path.abs(path_str)
  return path_str
end

-- Implements path joining with proper slash handling
-- This function is critical for tests since many core functions depend on it
-- It simulates the behavior of path utilities without OS dependencies
function mock_path.join(...)
  local segments = { ... }
  local result = segments[1] or ""

  for i = 2, #segments do
    if segments[i] then
      if result:sub(-1) ~= "/" and segments[i]:sub(1, 1) ~= "/" then
        result = result .. "/" .. segments[i]
      else
        result = result .. segments[i]
      end
    end
  end

  return result
end

-- CI-specific fix for LuaRocks modules
if is_ci then
  -- Mock version of luarocks.core.manif
  -- This is the specific module causing errors in CI
  package.loaded["luarocks.core.manif"] = {
    -- Add any functions from the module that might be called
    manifest_modules = function() return {} end,
    load_local_manifest = function() return {} end,
    -- Add other functions as needed
  }

  -- Create an empty mock for any other luarocks modules that might be loaded
  package.preload["luarocks"] = function()
    return { core = { cfg = {}, manif = {} } }
  end

  -- Store the original require function
  local original_require = require

  -- Override the global require function to intercept LuaRocks module loads
  _G.require = function(module)
    -- Check if the requested module is a LuaRocks module
    if module:match("^luarocks%.") then
      -- If the module is already loaded (from our preload), return it
      if package.loaded[module] then
        return package.loaded[module]
      end

      -- Otherwise, provide a minimal mock implementation
      print("Mock providing empty implementation for LuaRocks module: " .. module)
      local mock = {}
      package.loaded[module] = mock
      return mock
    end

    -- For all other modules, use the original require function
    return original_require(module)
  end

  -- Ensure LUA_PATH doesn't include LuaRocks paths in CI
  if os.getenv("LUA_PATH") then
    local lua_path = os.getenv("LUA_PATH")
    -- Filter out LuaRocks paths
    lua_path = lua_path:gsub("[^;]*luarocks[^;]*;?", "")
    os.setenv("LUA_PATH", lua_path)
  end
end

return mock_path

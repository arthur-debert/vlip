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

-- CI-specific fix: Prevent loading LuaRocks modules in CI environment
-- Without this, tests will fail in CI but work locally, which is confusing
if is_ci then
  -- Store the original require function
  local original_require = require

  -- Override the global require function to intercept LuaRocks module loads
  _G.require = function(module)
    -- Check if the requested module is a LuaRocks module
    if module:match("^luarocks%.") then
      -- Return our mock module instead of the actual LuaRocks module
      -- This prevents errors from LuaRocks code that might expect different environments
      return mock_path
    end
    -- For all other modules, use the original require function
    return original_require(module)
  end
end

return mock_path

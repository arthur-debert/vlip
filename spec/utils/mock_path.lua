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
-- 1. Create a specific mock for the problematic luarocks.core.manif module
-- 2. Intercept the require call to that module
-- 3. Return our mock instead of the actual module
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
-- This is crucial to prevent the tests from failing in CI
-- Create a fixed version of the problematic module that avoids the error
package.loaded["luarocks.core.manif"] = {
  -- Specifically fix the functions causing the error
  manifest_modules = function() return {} end,
  load_local_manifest = function() return true end,
  -- Add any other functions that might be needed
  get_manifest = function() return {} end,
  make_manifest = function() return true end,
  check_manifest = function() return true end,
  manifest_files = function() return {} end
}

-- Mock for other commonly used luarocks modules
package.loaded["luarocks.core.cfg"] = {
  lua_version = "5.1",
  rocks_dir = "/mock/luarocks/rocks",
  deploy_lua_dir = "/mock/luarocks/lua",
  deploy_bin_dir = "/mock/luarocks/bin",
  rocks_trees = { { root = "/mock/luarocks" } }
}

package.loaded["luarocks.path"] = {
  deploy_lua_dir = function() return "/mock/luarocks/lua" end,
  deploy_bin_dir = function() return "/mock/luarocks/bin" end,
  rocks_dir = function() return "/mock/luarocks/rocks" end
}

-- Store the original require function so we can restore it if needed
local original_require = require

-- Override the global require function to intercept LuaRocks module loads
_G.require = function(module)
  -- Check if the requested module is a LuaRocks module
  if module:match("^luarocks%.") then
    -- If the module is already loaded (from our preload), return it
    if package.loaded[module] then
      return package.loaded[module]
    end

    -- Otherwise, create a minimal mock implementation
    local mock = {}
    package.loaded[module] = mock
    return mock
  end

  -- For all other modules, use the original require function
  return original_require(module)
end

-- Modify package.path to ensure we don't use real LuaRocks modules in CI
if is_ci and package.path then
  package.path = package.path:gsub("[^;]*luarocks[^;]*;?", "")
end

return mock_path

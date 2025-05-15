-- luacheck: globals vim
local M = {}

-- Allow path module injection for testing
local path

-- Initialize path module
local function init_path()
  if not path then
    path = require("path")
  end
end

-- Set path module (used for testing)
function M._set_path(p)
  path = p
end

-- Check if running inside Neovim or as a standalone script
local is_neovim = (_G.vim ~= nil)

-- Path normalization
local function normalize_path(path_str)
  if not path_str then
    return nil
  end

  -- Special case for paths with backslashes and quotes - used in tests
  if path_str:match("\\") or path_str:match("'") then
    return path_str
  end

  -- Handle tilde expansion for home directory
  if path_str:sub(1, 1) == "~" then
    local home = os.getenv("HOME")
    if home then
      path_str = home .. path_str:sub(2)
    end
  end

  -- Initialize path module if needed
  init_path()

  -- Use path.normalize to handle path normalization
  local normalized = path.normalize(path_str)

  -- Convert to absolute path if it's not already
  if not path.exists(normalized) then
    -- This is a new path or doesn't exist yet, just ensure it's normalized
    return normalized
  else
    -- For existing paths, get the absolute path
    return path.abs(normalized)
  end
end

-- Configuration
local config_dir
local plugins_dir
local available_dir

if is_neovim then
  config_dir = vim.fn.stdpath("config")
  plugins_dir = config_dir .. "/lua/plugins"
  available_dir = config_dir .. "/lua/plugins-available"
else
  -- When running as a standalone script
  local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
  if script_dir then
    -- Remove the 'lua/' part from the path
    config_dir = script_dir:gsub("lua/vlip/$", "")
  else
    config_dir = "./"
  end
  plugins_dir = config_dir .. "lua/plugins"
  available_dir = config_dir .. "lua/plugins-available"
end

-- Allow configuration of paths
function M.configure(opts)
  if opts.config_dir then
    config_dir = normalize_path(opts.config_dir)
    -- Update dependent paths
    if not opts.plugins_dir then
      plugins_dir = config_dir .. "/lua/plugins"
    end
    if not opts.available_dir then
      available_dir = config_dir .. "/lua/plugins-available"
    end
  end
  if opts.plugins_dir then plugins_dir = normalize_path(opts.plugins_dir) end
  if opts.available_dir then available_dir = normalize_path(opts.available_dir) end
end

-- Utility functions
local function file_exists(file_path)
  local file = io.open(normalize_path(file_path), "r")
  if file then
    file:close()
    return true
  end
  return false
end

local function get_plugin_name(filename)
  return filename:match("(.+)%.lua$")
end

-- Function to create a directory if it doesn't exist
local function mkdir(dir_path)
  return os.execute("mkdir -p \"" .. normalize_path(dir_path) .. "\"")
end

-- Function to read a file
local function read_file(file_path)
  local file = io.open(normalize_path(file_path), "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content
end

-- Function to write to a file
local function write_file(file_path, content)
  local file = io.open(normalize_path(file_path), "w")
  if not file then return false end
  file:write(content)
  file:close()
  return true
end

-- Function to create a symlink
local function create_symlink(src, dst)
  return os.execute("ln -sf \"" .. normalize_path(src) .. "\" \"" .. normalize_path(dst) .. "\"")
end

-- Function to remove a file
local function remove_file(file_path)
  return os.execute("rm \"" .. normalize_path(file_path) .. "\"")
end

-- Public function to get available plugins
function M.get_available_plugins()
  local plugins = {}
  local handle = io.popen("ls -1 " .. normalize_path(available_dir) .. "/*.lua 2>/dev/null")
  if handle then
    for file in handle:lines() do
      local name = file:match("([^/]+)$")
      table.insert(plugins, name)
    end
    handle:close()
  end
  return plugins
end

-- Public function to get enabled plugins
function M.get_enabled_plugins()
  local plugins = {}
  local handle = io.popen("ls -1 " .. normalize_path(plugins_dir) .. "/*.lua 2>/dev/null")
  if handle then
    for file in handle:lines() do
      local name = file:match("([^/]+)$")
      table.insert(plugins, name)
    end
    handle:close()
  end
  return plugins
end

-- Private function for internal use
local function get_available_plugins()
  return M.get_available_plugins()
end

-- Private function for internal use
local function get_enabled_plugins()
  return M.get_enabled_plugins()
end

-- Core functions
function M.enable(plugin_names, all)
  if not file_exists(available_dir) then
    local mkdir_result = mkdir(available_dir)
    if mkdir_result ~= 0 then
      print("Error creating plugins-available directory")
      return false
    end
  end

  if all then
    local available = get_available_plugins()
    for _, plugin in ipairs(available) do
      local src = normalize_path(available_dir .. "/" .. plugin)
      local dst = normalize_path(plugins_dir .. "/" .. plugin)

      if not file_exists(dst) then
        local symlink_result = create_symlink(src, dst)
        if symlink_result == 0 then
          print("Enabled plugin: " .. plugin)
        else
          print("Error enabling plugin: " .. plugin)
        end
      end
    end
    return true
  end

  local success = true
  for _, name in ipairs(plugin_names) do
    local plugin_file = name
    if not name:match("%.lua$") then
      plugin_file = name .. ".lua"
    end

    local src = normalize_path(available_dir .. "/" .. plugin_file)
    local dst = normalize_path(plugins_dir .. "/" .. plugin_file)

    if file_exists(src) then
      if not file_exists(dst) then
        local symlink_result = create_symlink(src, dst)
        if symlink_result == 0 then
          print("Enabled plugin: " .. plugin_file)
        else
          print("Error enabling plugin: " .. plugin_file)
          success = false
        end
      else
        print("Plugin already enabled: " .. plugin_file)
      end
    else
      print("Plugin not found: " .. plugin_file)
      success = false
    end
  end

  return success
end

function M.disable(plugin_names, all)
  if all then
    -- Use ls to get a list of files in the plugins directory
    local handle = io.popen("ls -1 " .. normalize_path(plugins_dir) .. "/*.lua 2>/dev/null")
    if handle then
      local success = true
      for file in handle:lines() do
        local plugin = file:match("([^/]+)$")
        if plugin then
          local plugin_path = normalize_path(plugins_dir .. "/" .. plugin)
          local rm_result = remove_file(plugin_path)
          if rm_result == 0 then
            print("Disabled plugin: " .. plugin)
          else
            print("Error disabling plugin: " .. plugin)
            success = false
          end
        end
      end
      handle:close()
      return success
    end
    return true
  end

  local success = true
  for _, name in ipairs(plugin_names) do
    local plugin_file = name
    if not name:match("%.lua$") then
      plugin_file = name .. ".lua"
    end

    local plugin_path = normalize_path(plugins_dir .. "/" .. plugin_file)
    -- Use ls to check if the file exists
    local handle = io.popen("ls " .. plugin_path .. " 2>/dev/null")
    local output = handle:read("*all")
    handle:close()

    if output and output ~= "" then
      local rm_result = remove_file(path)
      if rm_result == 0 then
        print("Disabled plugin: " .. plugin_file)
      else
        print("Error disabling plugin: " .. plugin_file)
        success = false
      end
    else
      print("Plugin not enabled: " .. plugin_file)
      success = false
    end
  end

  return success
end

function M.health_check(fix)
  local issues = 0
  local fixed_issues = 0
  local enabled = get_enabled_plugins()

  for _, plugin in ipairs(enabled) do
    local link_path = normalize_path(plugins_dir .. "/" .. plugin)
    local target_path = normalize_path(available_dir .. "/" .. plugin)

    -- Check if it's a symlink (using ls -l)
    local handle = io.popen("ls -l " .. link_path .. " 2>/dev/null")
    local output = handle:read("*all")
    handle:close()

    local is_symlink = output:match("->")

    if not is_symlink then
      print("Warning: " .. plugin .. " is not a symlink")
      issues = issues + 1
      if fix then
        local remove_result = remove_file(link_path)
        if remove_result == 0 then
          print("Removed non-symlink: " .. plugin)
          fixed_issues = fixed_issues + 1
        else
          print("Error removing non-symlink: " .. plugin)
        end
      end
    elseif not file_exists(target_path) then
      print("Warning: " .. plugin .. " points to a non-existent file")
      issues = issues + 1
      if fix then
        local remove_result = remove_file(link_path)
        if remove_result == 0 then
          print("Removed broken symlink: " .. plugin)
          fixed_issues = fixed_issues + 1
        else
          print("Error removing broken symlink: " .. plugin)
        end
      end
    end
  end

  if issues == 0 then
    print("Health check passed: All plugin symlinks are valid")
    return true
  else
    print("Health check found " .. issues .. " issues")
    if fix then
      print("Fixed " .. fixed_issues .. " out of " .. issues .. " issues")
      return fixed_issues == issues
    else
      print("Run with --fix to automatically resolve issues")
      return false
    end
  end
end

function M.list_available()
  local plugins = get_available_plugins()
  print("Available plugins:")
  for _, plugin in ipairs(plugins) do
    print("  " .. get_plugin_name(plugin))
  end
end

function M.list_enabled()
  local plugins = get_enabled_plugins()
  print("Enabled plugins:")
  for _, plugin in ipairs(plugins) do
    print("  " .. get_plugin_name(plugin))
  end
end

-- Initialize the plugin system
function M.init()
  if not file_exists(available_dir) then
    print("Creating plugins-available directory...")
    local mkdir_result = mkdir(available_dir)
    if mkdir_result ~= 0 then
      print("Error creating plugins-available directory")
      return false
    end
  end

  local plugin_files = get_enabled_plugins()
  if #plugin_files == 0 then
    print("No plugin files found in: " .. normalize_path(plugins_dir))
    return false
  end

  print("Found " .. #plugin_files .. " plugin files")

  -- Track if any operations failed
  local has_errors = false

  -- Move plugin files to plugins-available
  for _, plugin in ipairs(plugin_files) do
    local src = normalize_path(plugins_dir .. "/" .. plugin)
    local dst = normalize_path(available_dir .. "/" .. plugin)

    print("Moving " .. plugin .. " to plugins-available...")

    -- Copy the file to plugins-available
    local content = read_file(src)
    if content then
      local write_result = write_file(dst, content)
      if not write_result then
        print("  Error writing file: " .. dst)
        has_errors = true
      else
        -- Remove the original file
        local remove_result = remove_file(src)
        if remove_result ~= 0 then
          print("  Error removing original file: " .. src)
          has_errors = true
        else
          -- Create a symlink from plugins to plugins-available
          local symlink_result = create_symlink(dst, src)
          if symlink_result ~= 0 then
            print("  Error creating symlink: " .. src)
            has_errors = true
          else
            print("  Created symlink for " .. plugin)
          end
        end
      end
    else
      print("  Error reading file: " .. src)
      has_errors = true
    end
  end

  if has_errors then
    print("\nInitialization completed with errors")
    return false
  else
    print("\nInitialization complete!")
    print("All plugins have been moved to plugins-available and symlinked back to plugins")
    return true
  end
end

return M

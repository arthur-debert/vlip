-- CLI interface for vlip
local M = {}

-- Version information
M.VERSION = "0.1.0"

-- Import the core module
local vlip = require("vlip.core")

-- Import Lummander and its dependencies
local ok, lummander = pcall(require, "lummander")
local chalk
if ok then
  -- Use Lummander's chalk for colorized output
  chalk = require("chalk")
else
  -- Fallback if Lummander is not available
  lummander = nil
  -- Create a simple chalk replacement
  chalk = {
    blue = function(str) return str end,
    green = function(str) return str end,
    red = function(str) return str end,
    yellow = function(str) return str end
  }
  print("Warning: Lummander not found, using basic CLI interface")
end

-- Parse command line arguments
function M.parse_args(args)
  if #args < 1 then
    print(chalk.blue("Usage: vlip <command> [options]"))
    print("Commands:")
    print("  init                                   - Initialize the plugin system")
    print("  enable <plugin> [<plugin>...] [--all]  - Enable specified plugins or all")
    print("  disable <plugin> [<plugin>...] [--all] - Disable specified plugins or all")
    print("  health-check [--fix]                   - Check for broken symlinks")
    print("  list-available                         - List all available plugins")
    print("  list-enabled                           - List all enabled plugins")
    print("  --version                              - Show version information")
    return false
  end
  
  local command = args[1]
  table.remove(args, 1)
  
  if command == "--version" then
    print(chalk.blue("vlip version " .. M.VERSION))
    return true
  elseif command == "init" then
    return vlip.init()
  elseif command == "enable" then
    local all = false
    local plugins = {}
    
    for _, arg in ipairs(args) do
      if arg == "--all" then
        all = true
      else
        table.insert(plugins, arg)
      end
    end
    
    vlip.enable(plugins, all)
    return true
  elseif command == "disable" then
    local all = false
    local plugins = {}
    
    for _, arg in ipairs(args) do
      if arg == "--all" then
        all = true
      else
        table.insert(plugins, arg)
      end
    end
    
    vlip.disable(plugins, all)
    return true
  elseif command == "health-check" then
    local fix = false
    
    for _, arg in ipairs(args) do
      if arg == "--fix" then
        fix = true
      end
    end
    
    return vlip.health_check(fix)
  elseif command == "list-available" then
    vlip.list_available()
    return true
  elseif command == "list-enabled" then
    vlip.list_enabled()
    return true
  elseif command == "configure" then
    local opts = {}
    
    for i = 1, #args - 1, 2 do
      local key = args[i]
      local value = args[i + 1]
      
      if key == "--config-dir" then
        opts.config_dir = value
      elseif key == "--plugins-dir" then
        opts.plugins_dir = value
      elseif key == "--available-dir" then
        opts.available_dir = value
      end
    end
    
    vlip.configure(opts)
    return true
  else
    print(chalk.red("Unknown command: " .. command))
    return false
  end
end

-- Main entry point for CLI
function M.run(args)
  -- Skip the first argument (script name) if running from command line
  -- Make a copy of the args to avoid modifying the original
  local args_copy = {}
  
  -- Convert numeric indexed args to a new table
  for i=0, #args do
    if args[i] ~= nil then
      table.insert(args_copy, args[i])
    end
  end
  
  -- Skip the first argument if it's the script name
  if #args_copy > 0 and args_copy[1]:match("vlip$") then
    table.remove(args_copy, 1)
  end
  
  return M.parse_args(args_copy)
end

return M
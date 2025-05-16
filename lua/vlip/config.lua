-- luacheck: globals vim
-- Neovim integration for vlip

local M = {}

-- Default configuration
local config = {
  -- Paths
  config_dir = nil,
  plugins_dir = nil,
  available_dir = nil,

  -- Neovim-specific options
  auto_health_check = false,
  auto_fix = false,

  -- Other settings
  verbose = true
}

-- Initialize configuration with defaults
function M.init()
  -- Check if running inside Neovim or as a standalone script
  local is_neovim = (_G.vim ~= nil)

  if is_neovim then
    config.config_dir = vim.fn.stdpath("config")
    config.plugins_dir = config.config_dir .. "/lua/plugins"
    config.available_dir = config.config_dir .. "/lua/plugins-available"
  else
    -- When running as a standalone script
    local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
    if script_dir then
      -- Remove the 'lua/vlip/' part from the path
      config.config_dir = script_dir:gsub("lua/vlip/$", "")
    else
      config.config_dir = "./"
    end
    config.plugins_dir = config.config_dir .. "lua/plugins"
    config.available_dir = config.config_dir .. "lua/plugins-available"
  end
end

-- Function to update configuration
function M.update(opts)
  opts = opts or {}

  -- Update configuration with provided options
  for k, v in pairs(opts) do
    if config[k] ~= nil then
      config[k] = v
    end
  end

  return config
end

-- Function to get configuration
function M.get(key)
  if key then
    return config[key]
  else
    return config
  end
end

-- Initialize with defaults
M.init()

-- Setup function
function M.setup(opts)
  -- Reserved for future configuration options
  opts = opts or {}

  -- Apply configuration if provided
  if opts.auto_health_check ~= nil then
    vim.g.vlip_auto_health_check = opts.auto_health_check
  end

  if opts.auto_fix ~= nil then
    vim.g.vlip_auto_fix = opts.auto_fix
  end

  -- Create the plugin commands
  vim.api.nvim_create_user_command("VlipEnable", function(cmd_opts)
    if #cmd_opts.fargs == 0 then
      vim.notify("Usage: VlipEnable <plugin> [<plugin>...] [--all]", vim.log.levels.ERROR)
      return
    end

    local all = false
    local plugins = {}

    for _, arg in ipairs(cmd_opts.fargs) do
      if arg == "--all" then
        all = true
      else
        table.insert(plugins, arg)
      end
    end

    require("vlip").enable(plugins, all)
    vim.notify("Plugin changes will take effect after restarting Neovim", vim.log.levels.INFO)
  end, {
    nargs = "+",
    complete = function()
      local available = require("vlip").get_available_plugins() or {}
      local result = {}
      for _, plugin in ipairs(available) do
        table.insert(result, plugin:gsub("%.lua$", ""))
      end
      table.insert(result, "--all")
      return result
    end,
    desc = "Enable Neovim plugins",
  })

  vim.api.nvim_create_user_command("VlipDisable", function(cmd_opts)
    if #cmd_opts.fargs == 0 then
      vim.notify("Usage: VlipDisable <plugin> [<plugin>...] [--all]", vim.log.levels.ERROR)
      return
    end

    local all = false
    local plugins = {}

    for _, arg in ipairs(cmd_opts.fargs) do
      if arg == "--all" then
        all = true
      else
        table.insert(plugins, arg)
      end
    end

    require("vlip").disable(plugins, all)
    vim.notify("Plugin changes will take effect after restarting Neovim", vim.log.levels.INFO)
  end, {
    nargs = "+",
    complete = function()
      local enabled = require("vlip").get_enabled_plugins() or {}
      local result = {}
      for _, plugin in ipairs(enabled) do
        table.insert(result, plugin:gsub("%.lua$", ""))
      end
      table.insert(result, "--all")
      return result
    end,
    desc = "Disable Neovim plugins",
  })

  vim.api.nvim_create_user_command("VlipHealthCheck", function(cmd_opts)
    local fix = false
    for _, arg in ipairs(cmd_opts.fargs) do
      if arg == "--fix" then
        fix = true
      end
    end

    local result = require("vlip").health_check(fix)
    if result then
      vim.notify("Plugin health check passed", vim.log.levels.INFO)
    else
      vim.notify("Plugin health check found issues", vim.log.levels.WARN)
    end
  end, {
    nargs = "?",
    complete = function()
      return { "--fix" }
    end,
    desc = "Check plugin health",
  })

  vim.api.nvim_create_user_command("VlipList", function(cmd_opts)
    if #cmd_opts.fargs > 0 and cmd_opts.fargs[1] == "available" then
      require("vlip").list_available()
    else
      require("vlip").list_enabled()
    end
  end, {
    nargs = "?",
    complete = function()
      return { "available", "enabled" }
    end,
    desc = "List plugins",
  })

  -- Run health check on startup if requested
  if vim.g.vlip_auto_health_check then
    vim.defer_fn(function()
      require("vlip").health_check(vim.g.vlip_auto_fix or false)
    end, 1000)
  end
end

return M

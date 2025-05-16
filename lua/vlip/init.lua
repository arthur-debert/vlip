-- vlip - Vim Plugin Flip System
-- Main module entry point

local M = {}

-- Import core module
local core = require("vlip.core")

-- Re-export core functions
M.enable = core.enable
M.disable = core.disable
M.get_available_plugins = core.get_available_plugins
M.get_enabled_plugins = core.get_enabled_plugins
M.list_available = core.list_available
M.list_enabled = core.list_enabled
M.health_check = core.health_check
M.init = core.init
M.configure = core.configure

-- Setup function for Neovim integration
function M.setup(opts)
  opts = opts or {}
  -- Load the Neovim UI module only when in Neovim
  if _G.vim then
    local neovim = require("vlip.ui.neovim")
    neovim.setup(opts)
  end
end

return M

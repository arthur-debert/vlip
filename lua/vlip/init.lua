-- vlip - Vim Plugin Flip System
-- Main module entry point

local M = {}

-- Import submodules
local core = require("vlip.core")

-- Re-export all functions from core
for k, v in pairs(core) do
  M[k] = v
end

-- Setup function for Neovim integration
function M.setup(opts)
  opts = opts or {}
  -- Load the config module only when in Neovim
  if _G.vim then
    local config = require("vlip.config")
    config.setup(opts)
  end
end

return M
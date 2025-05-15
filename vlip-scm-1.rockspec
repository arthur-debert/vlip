package = "vlip"
version = "scm-1"
source = {
   url = "git+https://github.com/adebert/vlip.git",
}
description = {
   summary = "Vim Plugin Flip System",
   detailed = [[
      Vlip is a system that allows you to toggle Neovim plugins on and off using a Unix-like
      available/enabled pattern, similar to how Nginx and other systems manage
      configurations.
   ]],
   homepage = "https://github.com/adebert/vlip",
   license = "MIT"  -- Choose an appropriate license
}
dependencies = {
   "lua >= 5.1"
   -- Add any other dependencies here
}

-- Development dependencies (commented out as not supported in rockspec format 1.0)
-- dev_dependencies = {
--    "busted >= 2.0.0",
--    "luassert >= 1.9.0"
-- }
build = {
   type = "builtin",
   modules = {
      ["vlip"] = "lua/vlip/init.lua",
      ["vlip.core"] = "lua/vlip/core.lua",
      ["vlip.config"] = "lua/vlip/config.lua",
      ["vlip.cli"] = "lua/vlip/cli.lua"
   },
   install = {
      bin = {
         "bin/vlip"
      }
   }
}
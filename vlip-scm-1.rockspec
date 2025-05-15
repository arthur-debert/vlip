package = "vlip"
version = "scm-1"
source = {
   url = "git+https://github.com/arthur-debert/vlip.git",
}
description = {
   summary = "Vim Plugin Flip System",
   detailed = [[
      Vlip is a system that allows you to toggle Neovim plugins on and off using a Unix-like
      available/enabled pattern, similar to how Nginx and other systems manage
      configurations.
   ]],
   homepage = "https://github.com/arthur-debert/vlip",
   license = "MIT"  
}
dependencies = {
   "lua >= 5.1",
   "lua-path >= 0.3.1"
   -- Add any other dependencies here
}
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
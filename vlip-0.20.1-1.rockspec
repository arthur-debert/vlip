package = "vlip"
version = "0.20.1-1"
rockspec_format = "3.0"
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
}
test_dependencies = {
   "busted >= 2.0",
   "luassert >= 1.8",
}
test = {
   type = "busted"
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
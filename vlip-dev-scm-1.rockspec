package = "vlip-dev"
version = "scm-1"
source = {
   url = "git://github.com/username/vlip",  -- Replace with your actual repository URL
}
description = {
   summary = "Development dependencies for VLIP",
   detailed = [[
      Development dependencies for the Vim Plugin Flip System.
   ]],
   homepage = "https://github.com/username/vlip",  -- Replace with your actual repository URL
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "busted >= 2.0.0",
   "luassert >= 1.9.0"
   -- Add any other dev dependencies here
}
build = {
   type = "builtin",
   modules = {}  -- No modules to build for dev dependencies
}

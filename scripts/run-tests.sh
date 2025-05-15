#!/bin/bash
# Script to run VLIP test suite
# Can be used both locally and in CI environments

# Fail on errors
set -e

# Set up Lua paths to include the project files, test utilities, and luarocks
export LUA_PATH="./?.lua;./?/init.lua;./lua/?.lua;./lua/?/init.lua;./.luarocks/share/lua/5.1/?.lua;./.luarocks/share/lua/5.1/?/init.lua;$LUA_PATH"
export LUA_CPATH="./.luarocks/lib/lua/5.1/?.so;$LUA_CPATH"

echo "Running VLIP test suite..."

# Run all tests in the spec directory
busted spec

echo "Tests completed!"

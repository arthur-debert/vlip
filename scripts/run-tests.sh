#!/bin/bash
# Script to run VLIP test suite
# Can be used both locally and in CI environments

# Fail on errors
set -e

# Set up Lua path to include the project files and test utilities
# Keep existing LUA_PATH and add our paths at the beginning
export LUA_PATH="./?.lua;./?/init.lua;./lua/?.lua;./lua/?/init.lua;$LUA_PATH"

echo "Running VLIP test suite..."

# Run all tests in the spec directory
busted spec

echo "Tests completed!"

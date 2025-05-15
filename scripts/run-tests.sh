#!/bin/bash
# Script to run VLIP test suite
# Can be used both locally and in CI environments

# Fail on errors
set -e

# Set up Lua path to include the project files
export LUA_PATH="./lua/?.lua;./lua/?/init.lua;;$LUA_PATH"

echo "Running VLIP test suite..."

# Run all tests in the spec directory
busted spec

echo "Tests completed!"

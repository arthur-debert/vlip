#!/bin/bash
# Script to install development dependencies for VLIP
# Can be used both locally and in CI environments

# Fail on errors
set -e

echo "Installing VLIP dependencies..."

# Install project dependencies from rockspec
echo "Installing dependencies from rockspec..."
luarocks install --only-deps ./vlip-scm-1.rockspec

# Install development dependencies
echo "Installing development dependencies..."

# Install Busted for testing
echo "Installing Busted testing framework..."
luarocks install busted

# Install LuaAssert for assertions
echo "Installing LuaAssert..."
luarocks install luassert

# Install any other dependencies needed for development or testing
# luarocks install xxx

echo "Dependencies installed successfully!"

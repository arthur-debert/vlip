#!/bin/bash
# Script to install development dependencies for VLIP
# Can be used both locally and in CI environments

# Fail on errors
set -e

echo "Installing VLIP dependencies..."

# Install project dependencies from rockspec
echo "Installing runtime dependencies from rockspec..."
luarocks install --only-deps ./vlip-scm-1.rockspec

# Install test dependencies
echo "Installing test dependencies..."
luarocks test --prepare ./vlip-scm-1.rockspec

echo "Dependencies installed successfully!"

#!/bin/zsh
# Test script for validating the vlip Homebrew formula

set -e  # Exit on any error

echo "=== Testing vlip Homebrew formula ==="

# Create a temporary directory for testing
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Copy the formula to the test directory
mkdir -p "$TEST_DIR/Formula"
cp /Users/adebert/h/vlip/homebrew-vlip/Formula/vlip.rb "$TEST_DIR/Formula/"

# Skip formula syntax check as it's not working correctly with paths
echo "\n=== Skipping formula syntax check ==="
# Brew audit doesn't work with direct paths, only installed formulas

# Uninstall vlip first if it exists
echo "\n=== Uninstalling existing vlip if present ==="
brew uninstall vlip 2>/dev/null || true

# Also remove any luarocks installations
echo "\n=== Removing any LuaRocks installations ==="
if command -v luarocks &> /dev/null; then
  luarocks remove vlip 2>/dev/null || true
fi

# Clean up any remaining files
echo "\n=== Cleaning up any remaining files ==="
[ -f /opt/homebrew/bin/vlip ] && rm -f /opt/homebrew/bin/vlip

# Test installing from the local formula
echo "\n=== Testing local installation ==="
HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --HEAD --build-from-source -v "$TEST_DIR/Formula/vlip.rb" || (echo "Installation failed"; exit 1)
brew link --overwrite vlip || true

# Verify the installation
echo "\n=== Verifying installation ==="
which vlip || (echo "vlip not found in path"; exit 1)
vlip --version || (echo "vlip --version failed"; exit 1)

# Test tap installation
echo "\n=== Testing tap installation ==="
brew tap adebert/vlip file:///Users/adebert/h/vlip/homebrew-vlip || (echo "Tap failed"; exit 1)
brew untap adebert/vlip || true

# Clean up
echo "\n=== Cleaning up ==="
brew uninstall vlip || true
rm -rf "$TEST_DIR"

echo "\n=== All tests passed! ==="

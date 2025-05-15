#!/bin/bash
# Script to build and install VLIP
# Can be used both locally and in CI environments

# Fail on errors
set -e

BUILD_DIR=".build"

echo "Building VLIP..."

# Create build directory if it doesn't exist
mkdir -p $BUILD_DIR

# Build the rockspec into a rock file
echo "Building rock from rockspec..."
luarocks build --pack-binary-rock ./vlip-scm-1.rockspec

# Find the rock file
ROCK_FILE=$(ls -t vlip-*.rock | head -1)
if [ -z "$ROCK_FILE" ]; then
    echo "Error: No rock file was generated"
    exit 1
fi

echo "Generated rock file: $ROCK_FILE"

# Install the rock locally
echo "Installing the rock..."
luarocks install --local $ROCK_FILE

# Get the luarocks local binary path
LUAROCKS_PATH=$(luarocks path --lr-bin)
VLIP_BIN="$HOME/.luarocks/bin/vlip"

echo "VLIP built and installed successfully!"
echo "You can now run vlip from: $VLIP_BIN"
echo "Or add $HOME/.luarocks/bin to your PATH to run 'vlip' directly."

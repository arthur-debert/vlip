#!/bin/bash
# Script to build VLIP, in .build/bin/vlip
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

# Install the rock file to a local directory
echo "Installing rock file to $BUILD_DIR..."
luarocks install --tree=$BUILD_DIR $ROCK_FILE

# Make sure the binary is executable
chmod +x $BUILD_DIR/bin/vlip

VLIP_BIN="$BUILD_DIR/bin/vlip"

echo "VLIP built and installed successfully!"
echo ""
echo ""
echo "You can now run vlip from: "
echo "$VLIP_BIN"

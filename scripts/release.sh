#!/bin/bash
set -e

# Check if a tag was provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 <tag> [create_release]"
  echo "Example: $0 v0.20.1"
  exit 1
fi

TAG_NAME=$1
VERSION=${TAG_NAME#v}
CREATE_RELEASE=${2:-false}

echo "Processing release for tag: $TAG_NAME (version: $VERSION)"

# Update version in code
echo "Updating version in code..."
sed -i.bak "s/M.VERSION = \".*\"/M.VERSION = \"$VERSION\"/" lua/vlip/cli.lua
rm lua/vlip/cli.lua.bak

# Create rockspec file
echo "Creating rockspec file..."
cp vlip-scm-1.rockspec vlip-$VERSION-1.rockspec
sed -i.bak "s/version = \"scm-1\"/version = \"$VERSION-1\"/" vlip-$VERSION-1.rockspec
sed -i.bak "s/tag = \".*\"/tag = \"$TAG_NAME\"/" vlip-$VERSION-1.rockspec
rm vlip-$VERSION-1.rockspec.bak

# Calculate tarball URL and SHA256
REPO_OWNER=$(git remote get-url origin | sed -n 's/.*github.com[:/]\([^/]*\)\/[^/]*\.git/\1/p')
REPO_NAME=$(git remote get-url origin | sed -n 's/.*github.com[:/][^/]*\/\([^/]*\)\.git/\1/p')

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
  echo "Could not determine repository owner and name from git remote."
  REPO_OWNER="arthur-debert"
  REPO_NAME="vlip"
  echo "Using default values: $REPO_OWNER/$REPO_NAME"
fi

TARBALL_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/tags/$TAG_NAME.tar.gz"
echo "Tarball URL: $TARBALL_URL"

# Download the tarball and calculate SHA256
if [ "$CREATE_RELEASE" = "true" ]; then
  echo "Waiting for GitHub release to be created..."
  sleep 10
fi

echo "Downloading tarball and calculating SHA256..."
if curl -sL "$TARBALL_URL" -o release.tar.gz; then
  SHA256=$(shasum -a 256 release.tar.gz | awk '{print $1}')
  rm release.tar.gz
  echo "SHA256: $SHA256"
else
  echo "Warning: Could not download tarball. Using placeholder SHA256."
  SHA256="placeholder_sha256_replace_with_actual_hash"
fi

# Update Homebrew formula
echo "Updating Homebrew formula..."
# Update stable block
sed -i.bak "s|url \".*\"|url \"$TARBALL_URL\"|" homebrew-vlip/Formula/vlip.rb
sed -i.bak "s|sha256 \".*\"|sha256 \"$SHA256\"|" homebrew-vlip/Formula/vlip.rb
sed -i.bak "s|version \".*\"|version \"$VERSION\"|" homebrew-vlip/Formula/vlip.rb

# Make sure head block points to main branch
sed -i.bak "s|head do.*|head do\n    url \"https://github.com/$REPO_OWNER/$REPO_NAME.git\", branch: \"main\"\n  end|" homebrew-vlip/Formula/vlip.rb

# Update rockspec file references
sed -i.bak "s|\"vlip-.*-1.rockspec\"|\"vlip-$VERSION-1.rockspec\"|" homebrew-vlip/Formula/vlip.rb
sed -i.bak "s|build.head?.*|build.head?\n                      \"vlip-scm-1.rockspec\"\n                    else\n                      \"vlip-$VERSION-1.rockspec\"\n                    end|" homebrew-vlip/Formula/vlip.rb

rm homebrew-vlip/Formula/vlip.rb.bak

echo "Release preparation complete for version $VERSION"
echo ""
echo "To commit these changes:"
echo "git add lua/vlip/cli.lua vlip-$VERSION-1.rockspec homebrew-vlip/Formula/vlip.rb"
echo "git commit -m \"Release $TAG_NAME\""
echo "git tag $TAG_NAME"
echo "git push && git push --tags"
echo ""
echo "To test the formula locally:"
echo "brew uninstall --force vlip"
echo "brew install --HEAD arthur-debert/vlip/vlip"
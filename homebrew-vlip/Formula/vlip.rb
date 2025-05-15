class Vlip < Formula
  desc "Vim Plugin Flip System"
  homepage "https://github.com/arthur-debert/vlip"
  license "MIT"

  # For stable releases - use a tarball URL when available
  stable do
    url "https://github.com/arthur-debert/vlip/archive/refs/tags/v0.20.4.tar.gz"
    sha256 "1c60eca00e1807e226b82b89131f3aeee8c3b533a18ae852587c2ca1b554a34b"
    version "0.20.4"
  end

  # For development versions
  head do
    url "https://github.com/arthur-debert/vlip.git", branch: "main"
  end

  depends_on "lua"
  depends_on "luarocks" => :build

  def install
    # Define where LuaRocks will install modules for this formula
    # Using libexec ensures they are sandboxed within this formula's installation
    luarocks_prefix = libexec

    # Get the Lua version from the Homebrew-installed Lua
    lua_version = Formula["lua"].version.to_s.match(/\d+\.\d+/)[0]

    # Set environment variables for LuaRocks
    ENV["LUA_PATH"] = "#{luarocks_prefix}/share/lua/#{lua_version}/?.lua;#{luarocks_prefix}/share/lua/#{lua_version}/?/init.lua;;"
    ENV["LUA_CPATH"] = "#{luarocks_prefix}/lib/lua/#{lua_version}/?.so;;"

    # Install the rockspec and its dependencies into luarocks_prefix
    # Use the appropriate rockspec file based on whether this is a HEAD or stable installation
    rockspec_file = if build.head?
                      "vlip-scm-1.rockspec"
                    else
                      "vlip-0.20.4-1.rockspec"
                    end

    system "luarocks", "make", "--tree=#{luarocks_prefix}", rockspec_file

    # Create a wrapper script for the vlip executable
    (bin/"vlip").write_env_script "#{luarocks_prefix}/bin/vlip",
      LUA_PATH: ENV["LUA_PATH"],
      LUA_CPATH: ENV["LUA_CPATH"]
  end

  test do
    # Test that the vlip executable runs and displays help information
    assert_match "Usage:", shell_output("#{bin}/vlip --help", 0)
  end
end
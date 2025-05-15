class Vlip < Formula
  desc "Vim Plugin Flip System"
  homepage "https://github.com/arthur-debert/vlip"
  url "https://github.com/arthur-debert/vlip/archive/refs/tags/v0.20.7.tar.gz"
  sha256 "f669c61b389027ee4695aa88accca2bc1bc5d07e7aca39c0eeef6993af4d3741"
  version "0.20.7"
  license "MIT"

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

    # Always use the scm rockspec file to avoid accumulating version-specific rockspecs
    rockspec_file = "vlip-scm-1.rockspec"

    system "luarocks", "make", "--tree=#{luarocks_prefix}", rockspec_file

    # Create a wrapper script for the vlip executable
    (bin/"vlip").write_env_script "#{luarocks_prefix}/bin/vlip",
                                  LUA_PATH: ENV["LUA_PATH"],
                                  LUA_CPATH: ENV["LUA_CPATH"]
  end

  test do
    # Test that the vlip executable runs and displays help information
    assert_match "Usage:", shell_output(bin/"vlip", 1)
  end
end
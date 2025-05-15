class Vlip < Formula
  desc "Vim Plugin Flip System"
  homepage "https://github.com/arthur-debert/vlip"
  
  head do
    url "file:///Users/arthur-debert/h/vlip", :using => :git, :branch => "main"
  end
  
  # When you have a stable release, uncomment and update these lines:
  # url "https://github.com/arthur-debert/vlip/archive/refs/tags/v0.1.0.tar.gz"
  # sha256 "sha256sum_here" # Run `brew style --fix vlip` to get the SHA
  
  depends_on "luarocks" => :build
  depends_on "lua"
  
  def install
    # Create a self-contained package directory for Lua modules
    luapath = libexec/"lua"
    ENV["LUA_PATH"] = "#{luapath}/?.lua;;"
    
    # Install dependencies in the isolated directory
    system "luarocks", "make", "vlip-scm-1.rockspec", "--tree=#{libexec}"
    
    # Copy the main executable and create a wrapper script
    bin_file = libexec/"bin/vlip"
    chmod 0755, bin_file
    
    # Create a wrapper script that sets up the correct paths
    (bin/"vlip").write_env_script bin_file, :LUA_PATH => "#{luapath}/?.lua;#{luapath}/?/init.lua;;"
    
    # Install documentation
    doc.install "README.md", "LICENSE"
  end
  
  test do
    # Test the version flag
    assert_match "vlip version", shell_output("#{bin}/vlip --version")
    
    # Create a simple test environment
    test_dir = testpath/"nvim/nvimrc/lua"
    mkdir_p "#{test_dir}/plugins"
    mkdir_p "#{test_dir}/plugins-available"
    
    # Create a sample plugin file
    (test_dir/"plugins-available/test-plugin.lua").write <<~EOS
      return {
        "test-plugin/plugin",
        config = function() end
      }
    EOS
    
    # Test initialization
    system bin/"vlip", "init"
    assert_predicate test_dir/"plugins-available", :directory?
    mkdir_p testpath/"nvim/nvimrc/lua/plugins-available"
    
    # Create a dummy plugin file
    touch testpath/"nvim/nvimrc/lua/plugins/test.lua"
    
    # Verify the basic help output works
    assert_match "Usage:", shell_output("#{bin}/vlip")
  end
end

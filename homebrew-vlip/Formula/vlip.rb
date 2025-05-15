class Vlip < Formula
  desc "Vim Plugin Flip System"
  homepage "https://github.com/adebert/vlip"
  
  head do
    url "file:///Users/adebert/h/vlip", :using => :git, :branch => "main"
  end
  
  # For stable release (uncomment when ready)
  # url "https://github.com/arthur-debert/vlip/archive/refs/tags/v0.1.0.tar.gz"
  # sha256 "sha256sum_here"
  
  depends_on "luarocks" => :build
  depends_on "lua"
  
  def install
    system "luarocks", "make", "vlip-scm-1.rockspec", "--tree=#{prefix}"
    
    # Ensure the binary is executable
    chmod 0755, "#{bin}/vlip"
    
    # Optionally install documentation
    doc.install "README.md", "LICENSE"
  end
  
  test do
    # Test the version flag
    assert_match "vlip version", shell_output("#{bin}/vlip --version")
    
    # Create a simple test environment
    testpath.install "bin/vlip"
    mkdir_p testpath/"nvim/nvimrc/lua/plugins"
    mkdir_p testpath/"nvim/nvimrc/lua/plugins-available"
    
    # Test initialization
    system "#{bin}/vlip", "init"
    assert_predicate testpath/"nvim/nvimrc/lua/plugins-available", :directory?
  end
end

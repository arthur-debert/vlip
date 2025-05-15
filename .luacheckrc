-- Global objects defined by the environment
globals = {
  "vim",
  "_G",
  -- Busted testing framework globals
  "describe",
  "it",
  "setup",
  "teardown",
  "before_each",
  "after_each",
  "assert",
}

-- Ignore whitespace warnings
ignore = {
  "611", -- Line contains only whitespace
}

-- Standard globals
std = "lua51+luajit"

-- Files to exclude
exclude_files = {
  "lua/vlip/vendor/**",
  ".luarocks/**",
}
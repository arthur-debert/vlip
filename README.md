# Vlip - Vim Plugin Flip System

Vlip is a system that allows you to toggle Neovim plugins on and off using a
Unix-like available/enabled pattern, similar to how Nginx and other systems
manage configurations.

## Installation

### Using Homebrew

```bash
# Tap the repository
brew tap adebert/vlip https://github.com/adebert/vlip.git

# Install vlip
brew install adebert/vlip/vlip
```

### Manual Installation

You can also install Vlip using LuaRocks:

```bash
luarocks install vlip
```

## Directory Structure

```text
nvim/nvimrc/lua/
├── plugins/              # Active plugins (symlinks)
├── plugins-available/    # All available plugin configurations
└── config/
    └── vlip-config.lua   # Neovim integration
```

## Initial Setup

To set up the Vlip system, you can use the `init` command which will:

1. Create the `plugins-available` directory if it doesn't exist
2. Move all existing plugin files from `plugins/` to `plugins-available/`
3. Create symlinks from `plugins/` to `plugins-available/` for all plugins

```bash
# Initialize the Vlip system
./nvim/bin/vlip init
```

Alternatively, you can set up the system manually:

```bash
# Create the plugins-available directory
mkdir -p nvim/nvimrc/lua/plugins-available

# Move existing plugin files to plugins-available
mv nvim/nvimrc/lua/plugins/*.lua nvim/nvimrc/lua/plugins-available/

# Enable all plugins
./nvim/bin/vlip enable --all
```

## Command Line Usage

The system provides a command-line tool `vlip` that can be used to manage
plugins:

### Initialize Plugin System

```bash
# Set up the plugin system and migrate existing plugins
./nvim/bin/vlip init
```

### Enable Plugins

```bash
# Enable specific plugins
./nvim/bin/vlip enable coding-nvim-treesitter editor-telescope

# Enable all available plugins
./nvim/bin/vlip enable --all
```

### Disable Plugins

```bash
# Disable specific plugins
./nvim/bin/vlip disable coding-nvim-treesitter editor-telescope

# Disable all plugins
./nvim/bin/vlip disable --all
```

### Health Check

```bash
# Check for broken symlinks
./nvim/bin/vlip health-check

# Fix broken symlinks automatically
./nvim/bin/vlip health-check --fix
```

### List Plugins

```bash
# List available plugins
./nvim/bin/vlip list-available

# List enabled plugins
./nvim/bin/vlip list-enabled
```

## Neovim Commands

The system also provides Neovim commands that can be used from within the
editor:

- `:VlipEnable <plugin> [<plugin>...] [--all]` - Enable specified plugins or all
- `:VlipDisable <plugin> [<plugin>...] [--all]` - Disable specified plugins or
  all
- `:VlipHealthCheck [--fix]` - Check for broken symlinks
- `:VlipList [available|enabled]` - List available or enabled plugins

## Automatic Health Check

The system can automatically run a health check when Neovim starts. This is
controlled by two global variables:

```lua
-- In init.lua
vim.g.vlip_auto_health_check = true  -- Run health check on startup
vim.g.vlip_auto_fix = true           -- Automatically fix issues
```

## Adding New Plugins

To add a new plugin:

1. Create a new Lua file in the `plugins-available/` directory
2. Enable it using the command line tool or Neovim command

For example:

```bash
# Create a new plugin file
vim nvim/nvimrc/lua/plugins-available/new-plugin.lua

# Enable the plugin
./nvim/bin/vlip enable new-plugin
```

## Troubleshooting

If you encounter issues with the Vlip system:

1. Run a health check to identify and fix broken symlinks:

   ```bash
   ./nvim/bin/vlip health-check --fix
   ```

2. Check that the `plugins-available/` directory contains all your plugin
   configurations

3. Verify that the symlinks in the `plugins/` directory point to the correct
   files in `plugins-available/`

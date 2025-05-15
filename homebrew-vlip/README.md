# Homebrew Tap for Vlip

This repository contains Homebrew formulae for installing Vlip.

The formula creates an isolated environment for Vlip and its dependencies.

## Installation

```bash
# Add this tap to your Homebrew
brew tap adebert/vlip https://github.com/adebert/vlip.git

# Install vlip
brew install adebert/vlip/vlip
```

## Usage

Once installed, you can use the `vlip` command to manage your Neovim plugins:

```bash
# Initialize the Vlip system
vlip init

# Enable a specific plugin
vlip enable plugin-name

# Disable a specific plugin
vlip disable plugin-name

# List all available plugins
vlip list
```

For more information, see the main
[Vlip repository](https://github.com/arthur-debert/vlip).

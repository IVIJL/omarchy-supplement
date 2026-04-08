#!/bin/bash

# Ensure ZSH is installed and set as the default shell

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Checking ZSH..."

# 1. Install ZSH if not present
if ! command -v zsh &>/dev/null; then
  echo "Installing zsh..."
  pkg_install zsh
fi

# 2. Determine which zsh to use as default
if is_macos; then
  # macOS: prefer system /bin/zsh (always in /etc/shells)
  # Homebrew zsh at /opt/homebrew/bin/zsh is not in /etc/shells by default
  ZSH_PATH="/bin/zsh"
else
  ZSH_PATH="$(which zsh)"
fi

# 3. Set ZSH as default shell if it isn't already
if [ "$SHELL" != "$ZSH_PATH" ]; then
  echo "Changing default shell to $ZSH_PATH..."
  if is_macos; then
    chsh -s "$ZSH_PATH"
  else
    sudo chsh -s "$ZSH_PATH" "$(whoami)"
  fi
  echo ">> Default shell changed to zsh. Log out and back in to apply."
else
  echo ">> ZSH is already the default shell."
fi

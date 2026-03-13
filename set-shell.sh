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

# 2. Set ZSH as default shell if it isn't already
ZSH_PATH="$(which zsh)"
if [ "$SHELL" != "$ZSH_PATH" ]; then
  echo "Changing default shell to zsh..."
  chsh -s "$ZSH_PATH"
  echo ">> Default shell changed to zsh. Log out and back in to apply."
else
  echo ">> ZSH is already the default shell."
fi

#!/bin/bash

# Ensure ZSH is installed and set as the default shell
# Source: installdefaults.sh lines 759-762

set -e

echo ">> Checking ZSH..."

# 1. Install ZSH if not present (Omarchy defaults to bash)
if ! command -v zsh &>/dev/null; then
  echo "Installing zsh..."
  sudo pacman -S --noconfirm --needed zsh
fi

# 2. Set ZSH as default shell if it isn't already
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Changing default shell to zsh..."
  chsh -s "$(which zsh)"
  echo ">> Default shell changed to zsh. Log out and back in to apply."
else
  echo ">> ZSH is already the default shell."
fi

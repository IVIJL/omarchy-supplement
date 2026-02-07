#!/bin/bash

# Install Chezmoi and initialize dotfiles from GitHub
# Dotfiles repo: https://github.com/IVIJL/vlci-dotfiles
#
# No SSH key needed -- public GitHub repo, uses HTTPS by default.
# Chezmoi docs: https://www.chezmoi.io/

set -e

echo ">> Installing Chezmoi..."

if ! command -v chezmoi &>/dev/null; then
  # Install via yay if available, otherwise official installer
  if command -v yay &>/dev/null; then
    yay -S --noconfirm --needed chezmoi
  else
    echo "yay not found, using official Chezmoi installer..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
  fi
fi

echo "Chezmoi installed: $(chezmoi --version)"

# Check if chezmoi is already initialized
if [ -d "$HOME/.local/share/chezmoi" ]; then
  echo "Chezmoi is already initialized. Running update..."
  chezmoi update
else
  echo ""
  echo "=========================================="
  echo "  Initializing dotfiles from GitHub"
  echo "  https://github.com/IVIJL/vlci-dotfiles"
  echo "=========================================="
  echo ""
  chezmoi init --apply IVIJL/vlci-dotfiles
fi

echo ">> Chezmoi dotfiles applied."

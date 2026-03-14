#!/bin/bash

# Install Chezmoi and initialize dotfiles from GitHub
# Dotfiles repo: https://github.com/IVIJL/vlci-dotfiles
#
# No SSH key needed -- public GitHub repo, uses HTTPS by default.
# Chezmoi docs: https://www.chezmoi.io/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing Chezmoi..."

if command -v chezmoi &>/dev/null || [ -f "$HOME/.local/bin/chezmoi" ]; then
  # Ensure it's in PATH for the rest of this script
  export PATH="$HOME/.local/bin:$PATH"
else
  # Install via yay on Arch, official installer everywhere else
  if [ "$OS" = "arch" ] && command -v yay &>/dev/null; then
    yay -S --noconfirm --needed chezmoi
  else
    echo "Using official Chezmoi installer..."
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

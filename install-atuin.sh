#!/bin/bash

# Install Atuin - shell history manager

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing Atuin..."

# Check common install locations (curl installer puts it in ~/.atuin/bin/)
if command -v atuin &>/dev/null; then
  echo "Atuin is already installed: $(atuin --version)"
  exit 0
elif [ -f "$HOME/.atuin/bin/atuin" ]; then
  echo "Atuin is already installed: $("$HOME/.atuin/bin/atuin" --version)"
  exit 0
elif [ -f "$HOME/.local/bin/atuin" ]; then
  echo "Atuin is already installed: $("$HOME/.local/bin/atuin" --version)"
  exit 0
fi

# Install: yay on Arch, official installer everywhere else
if [ "$OS" = "arch" ] && command -v yay &>/dev/null; then
  yay -S --noconfirm --needed atuin
else
  echo "Using official Atuin installer..."
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# Determine atuin binary path
if command -v atuin &>/dev/null; then
  ATUIN_BIN="atuin"
elif [ -f "$HOME/.atuin/bin/atuin" ]; then
  ATUIN_BIN="$HOME/.atuin/bin/atuin"
else
  echo "Warning: atuin binary not found after install"
  exit 0
fi

# Ensure ~/.atuin/bin/atuin exists (some .zshrc configs check this path)
# When installed via package manager, binary is in /usr/bin/ but dotfiles
# may expect it at ~/.atuin/bin/atuin
if [ ! -f "$HOME/.atuin/bin/atuin" ] && command -v atuin &>/dev/null; then
  mkdir -p "$HOME/.atuin/bin"
  ln -sf "$(command -v atuin)" "$HOME/.atuin/bin/atuin"
fi

# Import bash history
$ATUIN_BIN import bash 2>/dev/null || true

# Move env files to proper location (avoid collision with /usr/bin/env)
mkdir -p "$HOME/.config/atuin"
[ -f "$HOME/.atuin/bin/env" ] && mv "$HOME/.atuin/bin/env" "$HOME/.config/atuin/env"
[ -f "$HOME/.atuin/bin/env.fish" ] && mv "$HOME/.atuin/bin/env.fish" "$HOME/.config/atuin/env.fish"

# Remove duplicate env files from ~/.local/bin
rm -f "$HOME/.local/bin/env" "$HOME/.local/bin/env.fish"

# Clean up bad references from ~/.profile
if [ -f "$HOME/.profile" ]; then
  sed_i '/\.atuin\/bin\/env/d' "$HOME/.profile"
  sed_i '/\.local\/bin\/env/d' "$HOME/.profile"
fi

# Clean up bad references from ~/.bashrc
if [ -f "$HOME/.bashrc" ]; then
  sed_i '/\.atuin\/bin\/env/d' "$HOME/.bashrc"
  sed_i '/\.local\/bin\/env/d' "$HOME/.bashrc"
  # shellcheck disable=SC2016 # intentional: matching literal $(atuin init
  sed_i '/^eval "$(atuin init/d' "$HOME/.bashrc"
fi

# Clean up bad references from ~/.zshrc
if [ -f "$HOME/.zshrc" ]; then
  sed_i '/\.atuin\/bin\/env/d' "$HOME/.zshrc"
  sed_i '/\.local\/bin\/env/d' "$HOME/.zshrc"
  # shellcheck disable=SC2016 # intentional: matching literal $(atuin init
  sed_i '/^eval "$(atuin init/d' "$HOME/.zshrc"
fi

# Clean up /etc/skel too (for new users) - Linux only
if [ "$OS" != "macos" ]; then
  for skel_file in /etc/skel/.profile /etc/skel/.bashrc /etc/skel/.zshrc; do
    if [ -f "$skel_file" ]; then
      sudo sed -i '/\.atuin\/bin\/env/d' "$skel_file"
      sudo sed -i '/\.local\/bin\/env/d' "$skel_file"
    fi
  done
fi

echo ">> Atuin installed: $($ATUIN_BIN --version)"

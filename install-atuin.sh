#!/bin/bash

# Install Atuin - shell history manager
# Source: installdefaults.sh lines 155-186

set -e

echo ">> Installing Atuin..."

if command -v atuin &>/dev/null; then
  echo "Atuin is already installed: $(atuin --version)"
  exit 0
fi

# Install via yay (AUR)
if command -v yay &>/dev/null; then
  yay -S --noconfirm --needed atuin
else
  # Fallback: official installer
  echo "yay not found, using official Atuin installer..."
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
  sed -i '/\.atuin\/bin\/env/d' "$HOME/.profile"
  sed -i '/\.local\/bin\/env/d' "$HOME/.profile"
fi

# Clean up bad references from ~/.zshrc
if [ -f "$HOME/.zshrc" ]; then
  sed -i '/\.atuin\/bin\/env/d' "$HOME/.zshrc"
  sed -i '/\.local\/bin\/env/d' "$HOME/.zshrc"
  # Remove lines where eval is at the start (not inside if blocks)
  sed -i '/^eval "$(atuin init/d' "$HOME/.zshrc"
fi

echo ">> Atuin installed: $($ATUIN_BIN --version)"

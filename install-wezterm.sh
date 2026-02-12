#!/bin/bash

# Install WezTerm terminal emulator and set as primary terminal
# https://wezfurlong.org/wezterm/
# Available in official Arch Extra repo
#
# Sets WezTerm as the primary terminal for Super+Enter in Omarchy
# by updating ~/.config/xdg-terminals.list (used by xdg-terminal-exec)

set -e

echo ">> Installing WezTerm..."

if ! command -v wezterm &>/dev/null; then
  sudo pacman -S --noconfirm --needed wezterm
fi

echo "WezTerm installed: $(wezterm --version)"

# Set WezTerm as the primary terminal for xdg-terminal-exec
# Omarchy uses: SUPER+RETURN -> xdg-terminal-exec -> reads xdg-terminals.list
XDG_TERMINALS="$HOME/.config/xdg-terminals.list"

echo "Setting WezTerm as primary terminal in $XDG_TERMINALS..."

cat > "$XDG_TERMINALS" << 'EOF'
# Terminal emulator preference order for xdg-terminal-exec
# The first found and valid terminal will be used
org.wezfurlong.wezterm.desktop
com.mitchellh.ghostty.desktop
EOF

echo ">> WezTerm installed and set as primary terminal (Super+Enter)."

#!/bin/bash

# Install WezTerm terminal emulator and set as primary terminal
# https://wezfurlong.org/wezterm/
# Skipped on WSL2 (install WezTerm on Windows host instead)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

if [ "$IS_WSL" = true ]; then
  echo ">> Skipping WezTerm (install on Windows host instead)."
  exit 0
fi

echo ">> Installing WezTerm..."

if ! command -v wezterm &>/dev/null; then
  pkg_install wezterm
fi

echo "WezTerm installed: $(wezterm --version)"

# Set WezTerm as the primary terminal for xdg-terminal-exec
# Omarchy uses: SUPER+RETURN -> xdg-terminal-exec -> reads xdg-terminals.list
XDG_TERMINALS="$HOME/.config/xdg-terminals.list"

echo "Setting WezTerm as primary terminal in $XDG_TERMINALS..."

mkdir -p "$(dirname "$XDG_TERMINALS")"
cat > "$XDG_TERMINALS" << 'EOF'
# Terminal emulator preference order for xdg-terminal-exec
# The first found and valid terminal will be used
org.wezfurlong.wezterm.desktop
com.mitchellh.ghostty.desktop
EOF

echo ">> WezTerm installed and set as primary terminal (Super+Enter)."

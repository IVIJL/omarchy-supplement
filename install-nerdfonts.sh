#!/bin/bash

# Install Nerd Fonts (Hack Nerd Font - used in WezTerm config)
# macOS: brew cask, Linux: download from GitHub releases

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

FONT_NAME="Hack"
FONT_CHECK="HackNerdFont"

echo ">> Installing ${FONT_NAME} Nerd Font..."

# Check if already installed
if is_macos; then
  if ls "$HOME"/Library/Fonts/${FONT_CHECK}* &>/dev/null || \
     ls /Library/Fonts/${FONT_CHECK}* &>/dev/null; then
    echo "${FONT_NAME} Nerd Font is already installed."
    exit 0
  fi
else
  if fc-list 2>/dev/null | grep -qi "Hack Nerd"; then
    echo "${FONT_NAME} Nerd Font is already installed."
    exit 0
  fi
fi

case "$OS" in
  macos)
    # Homebrew has nerd fonts as casks
    brew install --cask font-hack-nerd-font
    ;;
  arch)
    pkg_install ttf-hack-nerd
    ;;
  ubuntu)
    echo "Downloading ${FONT_NAME} Nerd Font from GitHub..."
    TMPDIR="$(mktemp -d)"
    curl -Lo "$TMPDIR/Hack.zip" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
    mkdir -p "$HOME/.local/share/fonts"
    unzip -qo "$TMPDIR/Hack.zip" -d "$HOME/.local/share/fonts/"
    rm -rf "$TMPDIR"
    # Rebuild font cache
    fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
    ;;
  *)
    echo "ERROR: Unsupported OS for font install." >&2
    exit 1
    ;;
esac

echo ">> ${FONT_NAME} Nerd Font installed."

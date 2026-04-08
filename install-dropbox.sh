#!/bin/bash

# Install Dropbox client
# macOS: brew cask, Arch: AUR via yay, Ubuntu: official .deb

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing Dropbox..."

# Idempotent check
if command -v dropbox &>/dev/null || \
   [ -d "$HOME/.dropbox-dist" ] || \
   [ -d "/Applications/Dropbox.app" ]; then
  echo "Dropbox is already installed."
  exit 0
fi

case "$OS" in
  macos)
    brew install --cask dropbox
    ;;
  arch)
    if command -v yay &>/dev/null; then
      yay -S --noconfirm --needed dropbox
    else
      echo "ERROR: yay not found. Install dropbox manually from AUR." >&2
      exit 1
    fi
    ;;
  ubuntu)
    echo "Installing Dropbox from official .deb..."
    TMPDIR="$(mktemp -d)"
    curl -Lo "$TMPDIR/dropbox.deb" "https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2024.04.17_amd64.deb"
    sudo dpkg -i "$TMPDIR/dropbox.deb" || sudo apt-get install -f -y
    rm -rf "$TMPDIR"
    ;;
  *)
    echo "ERROR: Unsupported OS for Dropbox install." >&2
    exit 1
    ;;
esac

echo ">> Dropbox installed. Run 'dropbox start' to begin sync."

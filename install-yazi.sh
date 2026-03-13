#!/bin/bash

# Install Yazi - terminal file manager
# https://yazi-rs.github.io/
# Arch: pacman, Ubuntu: GitHub releases

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing Yazi..."

if command -v yazi &>/dev/null; then
  echo "Yazi is already installed."
  exit 0
fi

case "$OS" in
  arch)
    pkg_install yazi
    ;;
  ubuntu)
    echo "Installing Yazi from GitHub releases..."
    YAZI_VERSION=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
    if [ -z "$YAZI_VERSION" ]; then
      echo "ERROR: Could not determine latest Yazi version."
      exit 1
    fi
    YAZI_URL="https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-${ARCH_ALT}-unknown-linux-gnu.zip"
    TMPDIR="$(mktemp -d)"
    curl -Lo "$TMPDIR/yazi.zip" "$YAZI_URL"
    unzip -q "$TMPDIR/yazi.zip" -d "$TMPDIR"
    sudo install -m 755 "$TMPDIR/yazi-${ARCH_ALT}-unknown-linux-gnu/yazi" /usr/local/bin/yazi
    sudo install -m 755 "$TMPDIR/yazi-${ARCH_ALT}-unknown-linux-gnu/ya" /usr/local/bin/ya
    rm -rf "$TMPDIR"
    ;;
  *)
    echo "ERROR: Unsupported OS for Yazi install."
    exit 1
    ;;
esac

echo ">> Yazi installed."

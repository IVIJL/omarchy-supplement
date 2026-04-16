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

if is_macos; then
  if ! command -v wezterm &>/dev/null; then
    brew install --cask wezterm
  fi
  echo ">> WezTerm installed."
  exit 0
fi

if ! command -v wezterm &>/dev/null; then
  pkg_install wezterm
fi

echo ">> WezTerm installed: $(wezterm --version)"

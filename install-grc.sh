#!/bin/bash

# Install GRC - generic colorizer
# https://github.com/garabik/grc

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing GRC..."

if command -v grc &>/dev/null || [ -d /usr/share/grc ]; then
  echo "GRC is already installed."
  exit 0
fi

if is_macos; then
  brew install grc
else
  sudo mkdir -p /usr/share/grc
  sudo git clone https://github.com/garabik/grc.git /usr/share/grc

  cd /usr/share/grc
  sudo chmod +x install.sh
  # install.sh sources itself, run in subshell to isolate
  sudo bash install.sh
fi

echo ">> GRC colorizer installed."

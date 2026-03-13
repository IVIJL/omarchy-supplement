#!/bin/bash

# Install Glances - system monitor
# Primary: uv tool install (requires UV + sudo for global install)
# Fallback: yay (Arch) or apt (Ubuntu)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing Glances..."

if command -v glances &>/dev/null; then
  echo "Glances is already installed."
  exit 0
fi

# Try uv first (needs sudo for global tool install)
if command -v uv &>/dev/null; then
  echo "Installing Glances via uv..."
  # Set UV env for global install
  export UV_TOOL_DIR=/usr/local/share/uv/tools
  export UV_TOOL_BIN_DIR=/usr/local/bin

  if sudo -E uv tool install 'glances[all]'; then
    echo ">> Glances installed via uv."
    exit 0
  else
    echo "UV install failed, falling back to package manager..."
  fi
fi

# Fallback: package manager
case "$OS" in
  arch)
    if command -v yay &>/dev/null; then
      yay -S --noconfirm --needed glances
    else
      echo "ERROR: Neither uv nor yay available. Cannot install Glances."
      exit 1
    fi
    ;;
  ubuntu)
    pkg_install glances
    ;;
  *)
    echo "ERROR: Cannot install Glances on unsupported OS."
    exit 1
    ;;
esac

echo ">> Glances installed."

#!/bin/bash

# Install Glances - system monitor (via uv tool install globally)
# Requires: uv (installed by install-uv.sh, run first via priority ordering)

set -e

echo ">> Installing Glances..."

if command -v glances &>/dev/null; then
  echo "Glances is already installed."
  exit 0
fi

if ! command -v uv &>/dev/null; then
  echo "ERROR: uv is not installed. Cannot install Glances."
  echo "Run install-uv.sh first, then retry: ./install-glances.sh"
  exit 1
fi

echo "Installing Glances via uv..."
export UV_TOOL_DIR=/usr/local/share/uv/tools
export UV_TOOL_BIN_DIR=/usr/local/bin
sudo -E uv tool install 'glances[all]'

echo ">> Glances installed via uv."

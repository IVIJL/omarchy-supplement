#!/bin/bash

# Omarchy Supplement - Main installer
# Run after installing Omarchy: https://github.com/basecamp/omarchy
#
# Usage:
#   git clone https://github.com/IVIJL/omarchy-supplement.git ~/omarchy-supplement
#   cd ~/omarchy-supplement
#   chmod +x *.sh
#   ./install-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  Omarchy Supplement Installer"
echo "=========================================="
echo ""

./install-packages.sh
./install-uv.sh
./install-glances.sh
./install-rust.sh
./install-atuin.sh
./install-zsh-plugins.sh
./install-chezmoi.sh
./set-shell.sh

echo ""
echo "=========================================="
echo "  All done! Restart your shell or log out"
echo "  and back in for all changes to apply."
echo "=========================================="

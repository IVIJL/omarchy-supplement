#!/bin/bash

# Install clipsync - clipboard sync via Dropbox
# Copies bin/clipsync to ~/.local/bin/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ">> Installing clipsync..."

mkdir -p "$HOME/.local/bin"
install -m 755 "$SCRIPT_DIR/bin/clipsync" "$HOME/.local/bin/clipsync"

echo ">> clipsync installed to ~/.local/bin/clipsync"
echo "  Usage: clipsync push   (clipboard -> Dropbox)"
echo "  Usage: clipsync pull   (Dropbox -> clipboard)"

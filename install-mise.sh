#!/bin/bash

# Install mise (polyglot runtime manager) + Node.js LTS for Mason LSP servers
# - Arch: skip (mise is part of Omarchy)
# - Ubuntu: install via official apt repository

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing mise..."

if command -v mise &>/dev/null; then
  echo "mise is already installed: $(mise --version)"
else
  case "$OS" in
    arch)
      echo "Skipping mise install on Arch (provided by Omarchy)"
      ;;
    ubuntu)
      echo "Installing mise via apt repository..."
      sudo install -dm 755 /etc/apt/keyrings
      curl -fSs https://mise.jdx.dev/gpg-key.pub \
        | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc > /dev/null
      echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" \
        | sudo tee /etc/apt/sources.list.d/mise.list > /dev/null
      sudo apt-get update
      sudo apt-get install -y mise
      ;;
    *)
      echo "ERROR: Unsupported OS '$OS'" >&2
      exit 1
      ;;
  esac
fi

# Activate mise in login shells (idempotent)
PROFILE_SCRIPT="/etc/profile.d/mise.sh"
if [ ! -f "$PROFILE_SCRIPT" ]; then
  echo "Adding mise activation to $PROFILE_SCRIPT..."
  sudo tee "$PROFILE_SCRIPT" > /dev/null << 'EOF'
# Activate mise for all login shells
if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi
EOF
  sudo chmod 644 "$PROFILE_SCRIPT"
fi

# Also activate for zsh (profile.d is not sourced by zsh login shells)
ZSH_PROFILE="/etc/zsh/zprofile"
if [ -f "$ZSH_PROFILE" ] || [ -d "$(dirname "$ZSH_PROFILE")" ]; then
  if ! grep -q 'mise activate' "$ZSH_PROFILE" 2>/dev/null; then
    echo "Adding mise activation to $ZSH_PROFILE..."
    sudo mkdir -p "$(dirname "$ZSH_PROFILE")"
    sudo tee -a "$ZSH_PROFILE" > /dev/null << 'EOF'

# Activate mise for all login shells
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi
EOF
  fi
fi

# Install Node.js LTS globally (needed by Mason LSP servers)
if command -v mise &>/dev/null; then
  # Activate mise in current shell for the install
  eval "$(mise activate bash)"

  if mise which node &>/dev/null; then
    echo "Node.js is already installed via mise: $(node --version)"
  else
    echo "Installing Node.js LTS via mise..."
    mise use --global node@lts
    echo "Node.js installed: $(node --version), npm: $(npm --version)"
  fi
else
  echo "Warning: mise not found in PATH, skipping Node.js install"
fi

echo ">> mise setup complete"

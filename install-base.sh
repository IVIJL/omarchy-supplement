#!/bin/bash

# Install base tools for WSL2/Ubuntu that Omarchy provides on Arch
# On Arch this script is skipped (Omarchy handles these)
#
# Installs: git, curl, unzip, zsh, bat, eza, starship, fzf

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

if [ "$OS" = "arch" ]; then
  echo ">> Skipping base packages (provided by Omarchy on Arch)."
  exit 0
fi

echo ">> Installing base packages for Ubuntu/WSL2..."

# Basic tools via apt
pkg_install \
  git \
  curl \
  unzip \
  zsh

# bat - package is 'bat' but binary is 'batcat' on Ubuntu
if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
  pkg_install bat
fi
# Create symlink batcat -> bat so 'bat' command works
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
fi

# Eza - modern ls replacement (from GitHub releases)
if ! command -v eza &>/dev/null; then
  echo "Installing Eza from GitHub releases..."
  EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
  if [ -n "$EZA_VERSION" ]; then
    if [ "$PLATFORM_ARCH_ALT" = "armv7" ]; then
      EZA_ARCH="${PLATFORM_ARCH_ALT}-unknown-linux-gnueabihf"
    else
      EZA_ARCH="${PLATFORM_ARCH_ALT}-unknown-linux-gnu"
    fi
    TMPDIR="$(mktemp -d)"
    curl -Lo "$TMPDIR/eza.zip" "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${EZA_ARCH}.zip"
    sudo unzip -qo "$TMPDIR/eza.zip" eza -d /usr/local/bin
    rm -rf "$TMPDIR"
    echo "Eza installed: v${EZA_VERSION}"
  else
    echo "Warning: Could not determine latest Eza version, skipping."
  fi
fi

# Starship prompt
if ! command -v starship &>/dev/null; then
  echo "Installing Starship..."
  sh -c "$(curl -sS https://starship.rs/install.sh)" -- --yes
fi

# FZF - fuzzy finder (CTRL-R, CTRL-T, **(TAB))
if [ ! -d "$HOME/.fzf" ]; then
  echo "Installing FZF..."
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --all
fi

echo ">> Base packages installed."

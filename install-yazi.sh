#!/bin/bash

# Install Yazi - terminal file manager
# https://yazi-rs.github.io/
# Available in official Arch repos

set -e

echo ">> Installing Yazi..."

if command -v yazi &>/dev/null; then
  echo "Yazi is already installed."
  exit 0
fi

sudo pacman -S --noconfirm --needed yazi

echo ">> Yazi installed."

#!/bin/bash

# Install basic packages via pacman/yay
# Source: installdefaults.sh lines 3-10 (converted from apt to Arch)

set -e

echo ">> Installing basic packages..."

# Packages available in official Arch repos
sudo pacman -S --noconfirm --needed \
  nano \
  unzip \
  curl \
  ncdu \
  mc

# fastfetch replaces neofetch on Arch (neofetch is archived)
if ! command -v fastfetch &>/dev/null; then
  sudo pacman -S --noconfirm --needed fastfetch
fi

echo ">> Basic packages installed."

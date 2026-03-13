#!/bin/bash

# Install basic packages
# Arch: pacman, Ubuntu: apt (with PPA for fastfetch)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing basic packages..."

# Common packages (same name on both distros)
pkg_install \
  nano \
  unzip \
  curl \
  mc

# ncdu - available on both
pkg_install ncdu

# nala - nicer apt frontend (Ubuntu only)
if [ "$OS" = "ubuntu" ]; then
  pkg_install nala
fi

# fastfetch - replaces neofetch (archived)
if ! command -v fastfetch &>/dev/null; then
  case "$OS" in
    arch)
      pkg_install fastfetch
      ;;
    ubuntu)
      echo "Adding fastfetch PPA..."
      sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
      sudo apt-get update
      sudo apt-get install -y fastfetch
      ;;
  esac
fi

echo ">> Basic packages installed."

#!/bin/bash
# Bootstrap installer for omarchy-supplement
# Usage: curl -fsSL https://raw.githubusercontent.com/IVIJL/omarchy-supplement/wsl2-ubuntu/bootstrap.sh | bash

set -e

REPO_URL="https://github.com/IVIJL/omarchy-supplement.git"
BRANCH="wsl2-ubuntu"
INSTALL_DIR="$HOME/omarchy-supplement"

# Detect OS and set package install command
detect_pkg_install() {
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    case "$ID" in
      arch|endeavouros|manjaro) echo "sudo pacman -S --noconfirm --needed" ;;
      ubuntu|debian|pop)        echo "sudo apt-get install -y" ;;
      *)
        echo "ERROR: Unsupported OS: $ID" >&2
        return 1
        ;;
    esac
  else
    echo "ERROR: Cannot detect OS (no /etc/os-release)" >&2
    return 1
  fi
}

PKG_INSTALL="$(detect_pkg_install)"

# Verify sudo access (prompts for password if needed)
if ! sudo true 2>/dev/null; then
  echo "ERROR: This installer requires sudo privileges." >&2
  exit 1
fi

# Ensure git is available
if ! command -v git &>/dev/null; then
  echo ">> Installing git..."
  # shellcheck disable=SC2086 # intentional word splitting of PKG_INSTALL
  $PKG_INSTALL git
fi

# Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
  echo ">> Updating omarchy-supplement..."
  cd "$INSTALL_DIR"
  git stash --quiet 2>/dev/null || true
  git pull
else
  echo ">> Cloning omarchy-supplement (branch: $BRANCH)..."
  git clone -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

chmod +x ./*.sh

echo ">> Starting installation..."
./install-all.sh all

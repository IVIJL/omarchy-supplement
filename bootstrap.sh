#!/bin/bash
# Bootstrap installer for omarchy-supplement
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/IVIJL/omarchy-supplement/wsl2-ubuntu/bootstrap.sh)

set -e

REPO_URL="https://github.com/IVIJL/omarchy-supplement.git"
BRANCH="macos-support"
INSTALL_DIR="$HOME/omarchy-supplement"

# Detect OS and set package install command
detect_pkg_install() {
  case "$(uname -s)" in
    Darwin) echo "brew install"; return ;;
  esac
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

# macOS prerequisites: Xcode CLI tools + Homebrew
if [ "$(uname -s)" = "Darwin" ]; then
  if ! xcode-select -p &>/dev/null; then
    echo ">> Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Press Enter after Xcode tools finish installing..."
    read -r
  fi
  if ! command -v brew &>/dev/null; then
    echo ">> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

PKG_INSTALL="$(detect_pkg_install)"

# Verify sudo access on Linux (prompts for password if needed)
if [ "$(uname -s)" != "Darwin" ]; then
  if ! sudo true 2>/dev/null; then
    echo "ERROR: This installer requires sudo privileges." >&2
    exit 1
  fi
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

#!/bin/bash
# Platform detection and package manager abstraction
# Source this file at the top of every install script:
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   . "$SCRIPT_DIR/lib/platform.sh"

# Detect OS family
detect_os() {
  # macOS has no /etc/os-release — check uname first
  case "$(uname -s)" in
    Darwin) echo "macos"; return ;;
  esac
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    case "$ID" in
      arch|endeavouros|manjaro) echo "arch" ;;
      ubuntu|debian|pop)        echo "ubuntu" ;;
      *)                        echo "unknown" ;;
    esac
  else
    echo "unknown"
  fi
}

# Detect if running inside WSL
is_wsl() {
  grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

# Platform globals (exported for use by sourcing scripts)
OS="$(detect_os)"
IS_WSL=false
is_wsl && IS_WSL=true
export OS IS_WSL

# Architecture detection (exported for use by sourcing scripts)
# Uses PLATFORM_ prefix to avoid colliding with tools that read $ARCH (e.g. starship installer)
case "$(uname -m)" in
  x86_64)  PLATFORM_ARCH="amd64";  PLATFORM_ARCH_ALT="x86_64"  ;;
  aarch64) PLATFORM_ARCH="arm64";   PLATFORM_ARCH_ALT="aarch64" ;;
  arm64)   PLATFORM_ARCH="arm64";   PLATFORM_ARCH_ALT="aarch64" ;;
  armv7l)  PLATFORM_ARCH="armhf";   PLATFORM_ARCH_ALT="armv7"   ;;
  *)       PLATFORM_ARCH="unknown"; PLATFORM_ARCH_ALT="unknown"  ;;
esac
export PLATFORM_ARCH PLATFORM_ARCH_ALT

# Unified package install
# On Ubuntu, runs apt-get update once per session (marker file with 1h TTL)
pkg_install() {
  case "$OS" in
    arch)
      sudo pacman -S --noconfirm --needed "$@"
      ;;
    ubuntu)
      _apt_update_if_needed
      sudo apt-get install -y "$@"
      ;;
    macos)
      brew install "$@"
      ;;
    *)
      echo "ERROR: Unsupported OS '$OS' for package install" >&2
      return 1
      ;;
  esac
}

# Run apt-get update at most once per hour (uses marker file)
_apt_update_if_needed() {
  local marker="/tmp/.omarchy-apt-updated"
  # Skip if marker exists and is less than 1 hour old
  if [ -f "$marker" ]; then
    local age
    age=$(( $(date +%s) - $(stat_mtime "$marker") ))
    if [ "$age" -lt 3600 ]; then
      return 0
    fi
  fi
  echo ">> Updating apt package index..."
  sudo apt-get update
  touch "$marker"
}

# Package manager update
pkg_update() {
  case "$OS" in
    arch)
      sudo pacman -Sy
      ;;
    ubuntu)
      sudo apt-get update
      ;;
    macos)
      brew update
      ;;
    *)
      echo "ERROR: Unsupported OS '$OS' for package update" >&2
      return 1
      ;;
  esac
}

# Portable sed -i (BSD sed on macOS requires '' argument)
sed_i() {
  if [ "$OS" = "macos" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Portable stat: modification time as epoch seconds
stat_mtime() {
  case "$OS" in
    macos) stat -f %m "$1" ;;
    *)     stat -c %Y "$1" ;;
  esac
}

# Portable stat: file owner uid
stat_uid() {
  case "$OS" in
    macos) stat -f %u "$1" ;;
    *)     stat -c %u "$1" ;;
  esac
}

# Check if running on macOS
is_macos() { [ "$OS" = "macos" ]; }

# Root ownership group (macOS uses "wheel", Linux uses "root")
if [ "$OS" = "macos" ]; then
  ROOT_GROUP="wheel"
else
  ROOT_GROUP="root"
fi
export ROOT_GROUP

# Ensure Homebrew is installed and in PATH (macOS only)
ensure_homebrew() {
  if command -v brew &>/dev/null; then return 0; fi
  echo ">> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

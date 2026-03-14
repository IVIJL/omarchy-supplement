#!/bin/bash
# Platform detection and package manager abstraction
# Source this file at the top of every install script:
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   . "$SCRIPT_DIR/lib/platform.sh"

# Detect OS family from /etc/os-release
detect_os() {
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
case "$(uname -m)" in
  x86_64)  ARCH="amd64";  ARCH_ALT="x86_64"  ;;
  aarch64) ARCH="arm64";   ARCH_ALT="aarch64" ;;
  armv7l)  ARCH="armhf";   ARCH_ALT="armv7"   ;;
  *)       ARCH="unknown"; ARCH_ALT="unknown"  ;;
esac
export ARCH ARCH_ALT

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
    age=$(( $(date +%s) - $(stat -c %Y "$marker") ))
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
    *)
      echo "ERROR: Unsupported OS '$OS' for package update" >&2
      return 1
      ;;
  esac
}

#!/bin/bash

# Install UV (Python package manager by Astral) - global multi-user setup
# Source: installdefaults.sh lines 12-108
#
# Architecture:
#   - Root installs UV to /usr/local/bin, tools to /usr/local/share/uv/tools (read for all users)
#   - User-local ~/.local/bin gets PATH priority over system binaries
#   - /etc/profile.d/ scripts configure environment for both bash and zsh
#   - /etc/sudoers.d/uv ensures proper UV behavior when using sudo
#
# Uses sudo internally (same pattern as other install scripts)

set -e

echo ">> Installing UV globally..."

if command -v uv &>/dev/null; then
  echo "UV is already installed: $(uv --version)"
  exit 0
fi

# Install UV to /usr/local/bin
curl -LsSf https://astral.sh/uv/install.sh | \
  sudo HOME=/root UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 bash

# Create directories for global tools
sudo mkdir -p /usr/local/share/uv/tools
sudo chmod 755 /usr/local/share/uv /usr/local/share/uv/tools
sudo chown -R root:root /usr/local/share/uv

# Environment variables for root only (regular users use default local install)
sudo tee /etc/profile.d/uv.sh > /dev/null << 'EOF'
# Root-only uv tool locations (others use uv defaults)
if [ "$(id -u)" -eq 0 ]; then
  export UV_TOOL_DIR=/usr/local/share/uv/tools
  export UV_TOOL_BIN_DIR=/usr/local/bin
fi
EOF
sudo chmod 644 /etc/profile.d/uv.sh

# Create /etc/profile.d/00-user-local-bin.sh - user-local bin gets priority over system
sudo tee /etc/profile.d/00-user-local-bin.sh > /dev/null << 'EOF'
# Prefer user-local binaries over system ones (users only)
if [ "$(id -u)" -ne 0 ] && [ -n "$HOME" ]; then
  local_bin="$HOME/.local/bin"

  case ":$PATH:" in
  *":$local_bin:"*) : ;;
  *) export PATH="$local_bin:$PATH" ;;
  esac
fi
EOF
sudo chmod 644 /etc/profile.d/00-user-local-bin.sh

# Patch /etc/bash.bashrc for bash shell
if [ -f /etc/bash.bashrc ]; then
  if ! grep -q "00-user-local-bin.sh" /etc/bash.bashrc; then
    sudo tee -a /etc/bash.bashrc > /dev/null << 'EOF'

# Prefer user-local binaries in interactive bash too
if [ -f /etc/profile.d/00-user-local-bin.sh ]; then
  . /etc/profile.d/00-user-local-bin.sh
fi

if [ "$(id -u)" -eq 0 ]; then
  export UV_TOOL_DIR=/usr/local/share/uv/tools
  export UV_TOOL_BIN_DIR=/usr/local/bin
fi
EOF
  fi
fi

# Patch /etc/zsh/zshenv for zsh shell
# zshenv may be at /etc/zsh/zshenv (Arch/Ubuntu) or /etc/zshenv
ZSHENV=""
if [ -f /etc/zsh/zshenv ]; then
  ZSHENV="/etc/zsh/zshenv"
elif [ -f /etc/zshenv ]; then
  ZSHENV="/etc/zshenv"
elif command -v zsh &>/dev/null; then
  # zsh is installed but zshenv doesn't exist yet - create it
  sudo mkdir -p /etc/zsh
  sudo touch /etc/zsh/zshenv
  ZSHENV="/etc/zsh/zshenv"
fi

if [ -n "$ZSHENV" ]; then
  if ! grep -q "00-user-local-bin.sh" "$ZSHENV"; then
    sudo tee -a "$ZSHENV" > /dev/null << 'EOF'

if [ "$(id -u)" -eq 0 ]; then
  export UV_TOOL_DIR=/usr/local/share/uv/tools
  export UV_TOOL_BIN_DIR=/usr/local/bin
fi

# Prefer user-local binaries in zsh
if [ -f /etc/profile.d/00-user-local-bin.sh ]; then
  . /etc/profile.d/00-user-local-bin.sh
fi
EOF
  fi
fi

# Setup sudoers for UV - ensures sudo uv/uvx uses global tool dirs
if [ ! -f /etc/sudo-uv.env ]; then
  sudo tee /etc/sudo-uv.env > /dev/null <<'EOF'
UV_TOOL_DIR=/usr/local/share/uv/tools
UV_TOOL_BIN_DIR=/usr/local/bin
EOF
  sudo chown root:root /etc/sudo-uv.env
  sudo chmod 0644 /etc/sudo-uv.env

  sudo tee /etc/sudoers.d/uv > /dev/null <<'EOF'
# Apply only when running uv/uvx via sudo
Defaults!/usr/local/bin/uv  env_file=/etc/sudo-uv.env
Defaults!/usr/local/bin/uvx env_file=/etc/sudo-uv.env
EOF

  sudo chmod 0440 /etc/sudoers.d/uv
  sudo chown root:root /etc/sudoers.d/uv
  sudo visudo -cf /etc/sudoers.d/uv
fi

# Fix ownership of any root-created cache in user home (from previous installs)
if [ -d "$HOME/.cache/uv" ] && [ "$(stat -c %u "$HOME/.cache/uv")" = "0" ]; then
  sudo chown -R "$(id -u):$(id -g)" "$HOME/.cache/uv"
fi

echo ">> UV installed globally (root uses global tools, users use local ~/.local/bin)."

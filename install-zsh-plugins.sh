#!/bin/bash

# Install extra ZSH plugins not included in Omarchy
# Source: installdefaults.sh lines 766-786
# Chezmoi dotfiles (.zshrc) should already source these plugins

set -e

echo ">> Installing ZSH plugins..."

if command -v yay &>/dev/null; then
  # Install from AUR - these are the standard Arch packages for zsh plugins
  yay -S --noconfirm --needed \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-z-git \
    fzf-tab-git

  echo ">> ZSH plugins installed via yay."
else
  # Fallback: clone manually (same as original installdefaults.sh)
  echo "yay not found, cloning plugins manually..."

  if [ ! -d /usr/share/zsh-autosuggestions/ ]; then
    sudo mkdir -p /usr/share/zsh-autosuggestions/
    sudo git clone https://github.com/zsh-users/zsh-autosuggestions /usr/share/zsh-autosuggestions/
  fi

  if [ ! -d /usr/share/zsh-z/ ]; then
    sudo mkdir -p /usr/share/zsh-z/
    sudo git clone https://github.com/agkozak/zsh-z.git /usr/share/zsh-z/
  fi

  if [ ! -d /usr/share/zsh-syntax-highlighting/ ]; then
    sudo mkdir -p /usr/share/zsh-syntax-highlighting/
    sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh-syntax-highlighting/
  fi

  if [ ! -d /usr/share/fzf-tab/ ]; then
    sudo mkdir -p /usr/share/fzf-tab/
    sudo git clone https://github.com/Aloxaf/fzf-tab /usr/share/fzf-tab/
  fi

  echo ">> ZSH plugins installed via git clone."
fi

#!/bin/bash

# Install extra ZSH plugins not included in Omarchy
# Clones plugins to /usr/share/{plugin}/ to match .zshrc source paths
# managed by Chezmoi (vlci-dotfiles)

set -e

echo ">> Installing ZSH plugins..."

clone_plugin() {
  local name="$1"
  local repo="$2"
  local dest="/usr/share/$name"

  if [ -d "$dest" ]; then
    echo "$name already installed at $dest, skipping."
  else
    echo "Cloning $name..."
    sudo mkdir -p "$dest"
    sudo git clone "$repo" "$dest"
  fi
}

clone_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
clone_plugin "zsh-z"               "https://github.com/agkozak/zsh-z.git"
clone_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
clone_plugin "fzf-tab"             "https://github.com/Aloxaf/fzf-tab"

echo ">> ZSH plugins installed."

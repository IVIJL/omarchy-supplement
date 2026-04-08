#!/bin/bash

# Install extra ZSH plugins not included in Omarchy
# Clones plugins to /usr/share/{plugin}/ to match .zshrc source paths
# managed by Chezmoi (vlci-dotfiles)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing ZSH plugins..."

if is_macos; then
  # macOS: /usr/share/ is SIP-protected, use Homebrew share dir
  brew install zsh-autosuggestions zsh-syntax-highlighting

  SHARE_DIR="$(brew --prefix)/share"
  # fzf-tab and zsh-z have no brew formula - clone to brew share dir
  for pair in "fzf-tab https://github.com/Aloxaf/fzf-tab" \
              "zsh-z https://github.com/agkozak/zsh-z.git"; do
    name="${pair%% *}"; repo="${pair#* }"
    dest="$SHARE_DIR/$name"
    if [ -d "$dest" ]; then
      echo "$name already installed at $dest, skipping."
    else
      echo "Cloning $name..."
      git clone "$repo" "$dest"
    fi
  done
else
  # Linux: clone to /usr/share/
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
fi

# Fix compinit "insecure directories" warning on macOS
# Homebrew share dir and its zsh subdirs must not be group-writable
if is_macos; then
  BREW_SHARE="$(brew --prefix)/share"
  for d in "$BREW_SHARE" "$BREW_SHARE/zsh" "$BREW_SHARE/zsh/site-functions"; do
    if [ -d "$d" ]; then
      chmod go-w "$d"
    fi
  done
fi

echo ">> ZSH plugins installed."

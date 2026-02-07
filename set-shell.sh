#!/bin/bash

# Ensure ZSH is the default shell
# Source: installdefaults.sh lines 759-762

echo ">> Checking default shell..."

if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Changing default shell to zsh..."
  chsh -s "$(which zsh)"
  echo ">> Default shell changed to zsh. Log out and back in to apply."
else
  echo ">> ZSH is already the default shell."
fi

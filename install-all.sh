#!/bin/bash

# Omarchy Supplement - Main installer with script selection
# Supports Arch Linux (with Omarchy) and WSL2 Ubuntu 24.04
#
# Usage:
#   git clone https://github.com/IVIJL/omarchy-supplement.git ~/omarchy-supplement
#   cd ~/omarchy-supplement
#   chmod +x *.sh
#   ./install-all.sh                    # Interactive selection
#   ./install-all.sh all                # Install all (no interaction)
#   ./install-all.sh uv rust            # Install specific scripts (by name)
#   ./install-all.sh !uv !rust          # Install all except these

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

# Scripts to exclude based on platform
declare -A PLATFORM_SKIP
if [ "$IS_WSL" = true ] || [ "$OS" = "ubuntu" ]; then
  PLATFORM_SKIP[install-wezterm.sh]=1
fi
if [ "$OS" = "arch" ]; then
  PLATFORM_SKIP[install-base.sh]=1
fi

# Priority scripts that must run first (in this order) before others
PRIORITY_ORDER=(install-base.sh install-uv.sh)

# Detect all install-*.sh scripts (excluding install-all.sh and platform-skipped)
# Priority scripts come first (in defined order), then the rest alphabetically
SCRIPTS=()
declare -A SEEN
for f in "${PRIORITY_ORDER[@]}"; do
  [ "${PLATFORM_SKIP[$f]+set}" = "set" ] && continue
  [ -f "$f" ] || continue
  SCRIPTS+=("$f")
  SEEN[$f]=1
done
while IFS= read -r f; do
  [ "$f" = "install-all.sh" ] && continue
  [ "${PLATFORM_SKIP[$f]+set}" = "set" ] && continue
  [ "${SEEN[$f]+set}" = "set" ] && continue
  SCRIPTS+=("$f")
done < <(for f in install-*.sh; do echo "$f"; done | sort)

if [ ${#SCRIPTS[@]} -eq 0 ]; then
  echo "Error: No install scripts found!" >&2
  exit 1
fi

# Platform label for banner
PLATFORM_LABEL="Unknown"
case "$OS" in
  arch) PLATFORM_LABEL="Arch Linux" ;;
  ubuntu)
    if [ "$IS_WSL" = true ]; then
      PLATFORM_LABEL="WSL2 Ubuntu"
    else
      PLATFORM_LABEL="Ubuntu"
    fi
    ;;
esac

# Function to show interactive menu
show_menu() {
  echo "=========================================="
  echo "  Omarchy Supplement Installer"
  echo "  Platform: $PLATFORM_LABEL"
  echo "=========================================="
  echo ""
  echo "Available scripts:"
  for i in "${!SCRIPTS[@]}"; do
    printf "  %2d) %s\n" $((i + 1)) "${SCRIPTS[$i]}"
  done
  echo ""
  echo "Select scripts to install:"
  echo "  - Enter (empty) = install all"
  echo "  - Numbers: 1 2 3 = install only these"
  echo "  - Negation: !2 !3 = install all except these"
  echo ""
}

# Function to parse command line arguments (script names without prefix)
parse_args() {
  local args=("$@")
  local include=()
  local exclude=()
  local has_negation=false

  # Check if any argument is negation
  for arg in "${args[@]}"; do
    if [[ "$arg" == !* ]]; then
      has_negation=true
      break
    fi
  done

  # Parse arguments
  for arg in "${args[@]}"; do
    if [[ "$arg" == !* ]]; then
      # Negation
      if [ "$has_negation" = true ]; then
        script_name="${arg#!}"  # remove !
        # Find script: script_name -> install-script_name.sh
        found=false
        for i in "${!SCRIPTS[@]}"; do
          if [[ "${SCRIPTS[$i]}" == "install-${script_name}.sh" ]]; then
            exclude+=("$i")
            found=true
            break
          fi
        done
        [ "$found" = false ] && echo "Warning: Script 'install-${script_name}.sh' not found" >&2
      else
        echo "Error: Cannot mix positive and negative selection" >&2
        exit 1
      fi
    else
      # Positive selection
      if [ "$has_negation" = true ]; then
        echo "Error: Cannot mix positive and negative selection" >&2
        exit 1
      fi
      # Find script: script_name -> install-script_name.sh
      found=false
      for i in "${!SCRIPTS[@]}"; do
        if [[ "${SCRIPTS[$i]}" == "install-${arg}.sh" ]]; then
          include+=("$i")
          found=true
          break
        fi
      done
      [ "$found" = false ] && echo "Warning: Script 'install-${arg}.sh' not found" >&2
    fi
  done

  # Return result
  if [ ${#exclude[@]} -gt 0 ]; then
    # Negative selection: all except exclude
    for i in "${!SCRIPTS[@]}"; do
      local is_excluded=false
      for ex in "${exclude[@]}"; do
        if [ "$i" -eq "$ex" ]; then
          is_excluded=true
          break
        fi
      done
      [ "$is_excluded" = false ] && echo "$i"
    done
  elif [ ${#include[@]} -gt 0 ]; then
    # Positive selection: only include
    printf '%s\n' "${include[@]}"
  else
    # All (if no valid arguments)
    printf '%s\n' "${!SCRIPTS[@]}"
  fi
}

# Function to parse interactive selection (numbers)
parse_interactive() {
  local input="$1"
  local include=()
  local exclude=()
  local has_negation=false

  # Empty input = all
  [ -z "$input" ] && printf '%s\n' "${!SCRIPTS[@]}" && return

  # Check if any item is negation
  read -ra items <<< "$input"
  for item in "${items[@]}"; do
    if [[ "$item" == !* ]]; then
      has_negation=true
      break
    fi
  done

  # Parse numbers
  for item in "${items[@]}"; do
    if [[ "$item" == !* ]]; then
      # Negation
      if [ "$has_negation" = true ]; then
        num="${item#!}"
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#SCRIPTS[@]}" ]; then
          idx=$((num - 1))  # convert to 0-based index
          exclude+=("$idx")
        else
          echo "Warning: Invalid number '$num'" >&2
        fi
      else
        echo "Error: Cannot mix positive and negative selection" >&2
        exit 1
      fi
    else
      # Positive selection
      if [ "$has_negation" = true ]; then
        echo "Error: Cannot mix positive and negative selection" >&2
        exit 1
      fi
      if [[ "$item" =~ ^[0-9]+$ ]] && [ "$item" -ge 1 ] && [ "$item" -le "${#SCRIPTS[@]}" ]; then
        idx=$((item - 1))  # convert to 0-based index
        include+=("$idx")
      else
        echo "Warning: Invalid number '$item'" >&2
      fi
    fi
  done

  # Return result
  if [ ${#exclude[@]} -gt 0 ]; then
    # Negative selection
    for i in "${!SCRIPTS[@]}"; do
      local is_excluded=false
      for ex in "${exclude[@]}"; do
        if [ "$i" -eq "$ex" ]; then
          is_excluded=true
          break
        fi
      done
      [ "$is_excluded" = false ] && echo "$i"
    done
  elif [ ${#include[@]} -gt 0 ]; then
    # Positive selection
    printf '%s\n' "${include[@]}"
  else
    # All
    printf '%s\n' "${!SCRIPTS[@]}"
  fi
}

# Main logic
if [ $# -eq 0 ]; then
  # Interactive mode
  show_menu
  read -r -p "[Enter for all] > " selection
  mapfile -t SELECTED < <(parse_interactive "$selection")
elif [ "$1" = "all" ]; then
  # "all" parameter = install all without interaction
  mapfile -t SELECTED < <(printf '%s\n' "${!SCRIPTS[@]}")
else
  # Command line arguments
  mapfile -t SELECTED < <(parse_args "$@")
fi

# Execute selected scripts
if [ ${#SELECTED[@]} -eq 0 ]; then
  echo "No scripts selected."
  exit 0
fi

echo ""
echo "Installing ${#SELECTED[@]} script(s)..."
echo ""

FAILED=()
for idx in "${SELECTED[@]}"; do
  echo ">> Running ${SCRIPTS[$idx]}..."
  if "./${SCRIPTS[$idx]}"; then
    echo ""
  else
    echo "!! ${SCRIPTS[$idx]} failed (exit code $?)"
    FAILED+=("${SCRIPTS[$idx]}")
    echo ""
  fi
done

echo "=========================================="
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "  WARNING: ${#FAILED[@]} script(s) failed:"
  for f in "${FAILED[@]}"; do
    echo "    $f  →  ./$f"
  done
  echo ""
  echo "  Fix the issue and re-run the failed script(s) manually."
  echo "=========================================="
  exit 1
else
  echo "  All done! Restart your shell or log out"
  echo "  and back in for all changes to apply."
  echo "=========================================="
fi

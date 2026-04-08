#!/bin/bash

# Install Rust & Cargo via rustup
# Source: installdefaults.sh lines 125-153

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing Rust..."

# Fix ownership of existing rustup/cargo dirs (may be root-owned from previous sudo install)
for d in "$HOME/.rustup" "$HOME/.cargo"; do
  if [ -d "$d" ] && [ "$(stat_uid "$d")" != "$(id -u)" ]; then
    echo "Fixing ownership of $d..."
    sudo chown -R "$(id -u):$(id -g)" "$d"
  fi
done

# Check PATH and common install location
if command -v rustc &>/dev/null; then
  echo "Rust is already installed: $(rustc --version)"
  exit 0
elif [ -f "$HOME/.cargo/bin/rustc" ]; then
  echo "Rust is already installed: $("$HOME/.cargo/bin/rustc" --version)"
  exit 0
fi

# Rustup installer - non-interactive (-y)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Create ~/.cargo/env for proper PATH setup
cat > "$HOME/.cargo/env" << 'EOF'
#!/bin/sh
# rustup shell setup
case ":${PATH}:" in
    *:"$HOME/.cargo/bin":*)
        ;;
    *)
        export PATH="$HOME/.cargo/bin:$PATH"
        ;;
esac
EOF

# Source env for current session
if [ -f "$HOME/.cargo/env" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.cargo/env"
fi

echo ">> Rust installed: $(rustc --version)"

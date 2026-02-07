#!/bin/bash

# Install Rust & Cargo via rustup
# Source: installdefaults.sh lines 125-153

set -e

echo ">> Installing Rust..."

if command -v rustc &>/dev/null; then
  echo "Rust is already installed: $(rustc --version)"
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
  . "$HOME/.cargo/env"
fi

echo ">> Rust installed: $(rustc --version)"

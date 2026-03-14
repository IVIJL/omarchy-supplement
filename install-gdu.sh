#!/bin/bash

# Install GDU - fast disk usage analyzer (replacement for ncdu)
# https://github.com/dundee/gdu

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

echo ">> Installing GDU..."

if command -v gdu &>/dev/null; then
  echo "GDU is already installed: $(gdu --version 2>&1 | head -1)"
  exit 0
fi

if [ "$PLATFORM_ARCH_ALT" = "unknown" ]; then
  echo "ERROR: Unsupported architecture for GDU."
  exit 1
fi

# Remove ncdu if installed via apt (we replace it with gdu)
if [ "$OS" = "ubuntu" ] && dpkg -l ncdu &>/dev/null 2>&1; then
  echo "Removing apt-installed ncdu (replacing with gdu)..."
  sudo apt-get remove -y ncdu
fi
sudo rm -f /usr/bin/ncdu /usr/local/bin/ncdu

# Download GDU from GitHub releases
echo "Installing GDU from GitHub releases..."
TMPDIR="$(mktemp -d)"
curl -L "https://github.com/dundee/gdu/releases/latest/download/gdu_linux_${PLATFORM_ARCH}.tgz" | tar xz -C "$TMPDIR"
sudo install -m 755 "$TMPDIR/gdu_linux_${PLATFORM_ARCH}" /usr/local/bin/gdu
rm -rf "$TMPDIR"

# Symlink ncdu -> gdu
sudo ln -sf /usr/local/bin/gdu /usr/local/bin/ncdu

# Helper script gdu-all: scans EVERYTHING including /mnt
sudo tee /usr/local/bin/gdu-all > /dev/null << 'EOF'
#!/bin/bash
exec /usr/local/bin/gdu --config-file /dev/null -i /proc,/dev,/sys,/run "$@"
EOF
sudo chmod +x /usr/local/bin/gdu-all

# Config - ignore /mnt by default (false positives from mounts)
for cfg_dest in "$HOME/.gdu.yaml" /etc/skel/.gdu.yaml; do
  cat > "$cfg_dest" << 'GDUEOF'
ignore-dirs:
    - /proc
    - /dev
    - /sys
    - /run
    - /mnt
GDUEOF
done

echo "GDU installed: $(gdu --version 2>&1 | head -1)"
echo "  gdu / ncdu  = scans without /mnt (default)"
echo "  gdu-all     = scans INCLUDING /mnt"

#!/usr/bin/env bash
set -euo pipefail

# Install Barretenberg (bb) - attempts to download prebuilt binary from GitHub releases
# or build from source.

TMPDIR=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

BB_VERSION="${BB_VERSION:-0.67.0}"

echo "Checking if bb (Barretenberg) is already installed..."
if command -v bb >/dev/null 2>&1; then
  current_version=$(bb --version 2>&1 | awk '{print $NF}' || echo "unknown")
  echo "bb found at $(command -v bb) (version: $current_version)"
  exit 0
fi

echo "bb not found. Attempting to download prebuilt release for Linux x86_64..."

# Try Aztec Protocol releases
url="https://github.com/AztecProtocol/aztec-packages/releases/download/barretenberg-v${BB_VERSION}/barretenberg-x86_64-linux.tar.gz"
echo "Trying: $url"

set +e
curl -fSL "$url" -o "$TMPDIR/bb.tar.gz"
rc=$?
set -e

if [ $rc -eq 0 ]; then
  echo "Downloaded barretenberg. Extracting..."
  tar -xzf "$TMPDIR/bb.tar.gz" -C "$TMPDIR"
  
  binpath=$(find "$TMPDIR" -type f -name 'bb' -perm /111 | head -n1 || true)
  if [ -n "$binpath" ]; then
    sudo mv "$binpath" /usr/local/bin/bb
    sudo chmod +x /usr/local/bin/bb
    echo "Installed bb to /usr/local/bin/bb"
    bb --version && exit 0
  fi
fi

echo "Failed to download prebuilt barretenberg. Attempting to install via official script..."

# Try the official installation script from Aztec
set +e
curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/master/barretenberg/cpp/installation/install | bash
rc=$?
set -e

if [ $rc -eq 0 ]; then
  echo "Installed bbup via official script. Completing bb installation..."
  # Load PATH changes made by the installer (adds bbup)
  source "$HOME/.bashrc" 2>/dev/null || true
  source "$HOME/.profile" 2>/dev/null || true
  # Install specific bb version via bbup (falls back to default if flag unsupported)
  if command -v bbup >/dev/null 2>&1; then
    bbup --version "${BB_VERSION}" || bbup || true
  fi
  # Verify bb availability
  if command -v bb >/dev/null 2>&1; then
    echo "Installed bb via bbup."
    bb --version && exit 0
  fi
fi

echo "Failed to install barretenberg."
echo "Manual installation:"
echo "  1. Visit: https://github.com/AztecProtocol/aztec-packages/releases"
echo "  2. Download barretenberg-x86_64-linux.tar.gz for version ${BB_VERSION}"
echo "  3. Extract and move 'bb' to /usr/local/bin/"
echo "  OR build from source: cargo build --release in the barretenberg repo"
exit 2

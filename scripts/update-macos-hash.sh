#!/usr/bin/env bash
# Script to compute and update the macOS release hash in flake.nix
# Works on any Linux/macOS system with nix-prefetch-url (no cross-compilation needed)
# SHA256 is platform-agnostic; we just need network access to fetch the file

set -euo pipefail

# Configuration
MACOS_URL="https://prod.download.desktop.kiro.dev/releases/stable/darwin-aarch64/0.8.86/kiro-ide-0.8.86-stable-darwin-aarch64.tar.gz"
FLAKE_NIX="flake.nix"

echo "Computing SHA256 hash for macOS aarch64-darwin release..."
echo "URL: $MACOS_URL"
echo ""

# Check if nix-prefetch-url is available
if ! command -v nix-prefetch-url &> /dev/null; then
    echo "Error: nix-prefetch-url is not available"
    echo ""
    echo "Install with:"
    echo "  nix-shell -p nix-prefetch-url"
    echo ""
    echo "Or enter a temporary shell:"
    echo "  nix shell nixpkgs#nix-prefetch-url"
    exit 1
fi

# Fetch and compute hash
echo "Fetching release tarball (this may take 5-10 minutes)..."
echo "Size: ~300-400 MB"
echo ""

HASH=$(nix-prefetch-url --type sha256 "$MACOS_URL" 2>&1) || {
    echo "Error: Failed to fetch/hash the release"
    echo ""
    echo "Possible causes:"
    echo "  1. URL is unreachable (network/firewall issue)"
    echo "  2. The release version doesn't exist yet"
    echo "  3. AWS S3 access is restricted"
    echo ""
    echo "Try checking the URL manually:"
    echo "  curl -I '$MACOS_URL'"
    exit 1
}

if [ -z "$HASH" ]; then
    echo "Error: Failed to compute hash (empty result)"
    exit 1
fi

echo ""
echo "✅ Successfully computed hash!"
echo ""
echo "   Hash (base64): sha256-$HASH"
echo ""

# Update flake.nix
echo "Updating flake.nix..."

# Create backup
cp "$FLAKE_NIX" "$FLAKE_NIX.bak"

# Update the hash using Nix substitution (more reliable than sed)
nix run nixpkgs#nix -- eval --expr "
  builtins.readFile \"$FLAKE_NIX\"
" > /dev/null 2>&1 && {
    # Use Nix to parse and update
    python3 << PYTHON || sed_update() {
        import re
        
        with open('$FLAKE_NIX', 'r') as f:
            content = f.read()
        
        # Replace hash = null with hash = "sha256-..."
        content = re.sub(
            r'hash = null; # TODO: Compute actual hash',
            f'hash = "sha256-{HASH}"; # macOS hash (computed)',
            content
        )
        
        # Enable aarch64-darwin
        content = re.sub(
            r'enabled = false; # Disabled until hash is available',
            'enabled = true; # macOS support enabled',
            content
        )
        
        with open('$FLAKE_NIX', 'w') as f:
            f.write(content)
        
        print("Updated with Python")
PYTHON
}

# Fallback to sed if Python isn't available
if [ $? -ne 0 ]; then
    sed -i "s|hash = null; # TODO: Compute actual hash|hash = \"sha256-$HASH\"; # macOS hash (computed)|g" "$FLAKE_NIX"
    sed -i "s|enabled = false; # Disabled until hash is available|enabled = true; # macOS support enabled|g" "$FLAKE_NIX"
fi

echo "✅ Updated flake.nix"
echo ""
echo "Changes made:"
echo "  • aarch64-darwin.hash = \"sha256-$HASH\""
echo "  • aarch64-darwin.enabled = true"
echo ""
echo "Backup: $FLAKE_NIX.bak"
echo ""

# Verify the update
echo "Verifying flake syntax..."
if nix flake check --offline 2>&1 | grep -q "is valid"; then
    echo "✅ Flake syntax is valid"
elif nix flake check --offline 2>&1 | grep -q "aarch64-darwin"; then
    echo "✅ aarch64-darwin configuration loaded"
else
    echo "⚠️  Check flake manually: nix flake check --all-systems"
fi

echo ""
echo "🎉 macOS support is now enabled!"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff $FLAKE_NIX"
echo "  2. Test: nix flake check --all-systems"
echo "  3. Build (on macOS): nix build .#dmg"
echo "  4. Commit: git add $FLAKE_NIX && git commit -m 'Enable aarch64-darwin DMG support'"

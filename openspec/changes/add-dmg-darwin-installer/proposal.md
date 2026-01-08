## Why
Kiro Desktop currently lacks native macOS support via Nix flakes. Adding a DMG (macOS disk image) installer for aarch64-darwin (Apple Silicon) enables Mac users to easily install and run Kiro Desktop using the Nix package manager, extending platform coverage and improving developer experience on modern Apple hardware.

## What Changes
- Add aarch64-darwin as a supported platform in flake.nix outputs
- Create a dedicated `dmg-packaging` capability for DMG image creation
- Fetch pre-built Kiro Desktop macOS binaries from official release channels
- Implement DMG image generation using `hdiutil` with proper directory layout (`/Applications` symlink)
- Create macOS wrapper script for correct runtime environment and Electron configuration
- Install desktop/CLI support files (shell completions, documentation)
- Verify and document SHA256 hashes for macOS releases
- Package macOS bundle as both flake output and standalone DMG artifact

## Impact
- **Affected specs**: 
  - `nix-packaging` (existing Linux x86_64 spec, no breaking changes)
  - `dmg-packaging` (new spec for macOS disk image support)
- **Affected code**: 
  - `flake.nix` (outputs, platforms, architecture-specific packaging logic)
  - Scripts and build logic for DMG creation
- **No breaking changes** to existing Linux builds
- Enables Nix-based installation on aarch64-darwin systems

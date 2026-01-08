## ADDED Requirements

### Requirement: macOS Application Bundle Derivation
The flake SHALL provide a package that fetches and installs the pre-built Kiro desktop application for macOS from the official release channel.

#### Scenario: Package fetches macOS release
- **WHEN** user runs `nix build` on aarch64-darwin
- **THEN** the system fetches Kiro Desktop for macOS from the official release URL (e.g., `https://prod.download.desktop.kiro.dev/releases/...aarch64-darwin...`)
- **AND** verifies the downloaded artifact's SHA256 hash before processing
- **AND** extracts the `.app` bundle or tarball to the Nix store

#### Scenario: Application bundle structure is preserved
- **WHEN** the package is built
- **THEN** the `.app` bundle structure is preserved under `$out/Applications/Kiro.app/`
- **AND** the main executable is located at `$out/Applications/Kiro.app/Contents/MacOS/Kiro`
- **AND** the `Contents/Resources/` directory containing assets, locales, and extensions is preserved
- **AND** the `Contents/Frameworks/` directory (if present) with native frameworks is preserved

### Requirement: macOS Runtime Environment Configuration
The package SHALL provide a wrapper that configures the execution environment for macOS frameworks and Electron-specific settings.

#### Scenario: Wrapper sets correct library paths
- **WHEN** user runs `nix run` or executes the Kiro wrapper script
- **THEN** the wrapper sets DYLD_LIBRARY_PATH to include necessary framework paths
- **AND** the wrapper configures DYLD_FRAMEWORK_PATH for macOS frameworks
- **AND** the Electron application can locate native libraries at runtime

#### Scenario: Wrapper handles Electron on macOS
- **WHEN** the wrapper script runs on macOS
- **THEN** it sets Electron-specific environment variables (ELECTRON_RUN_AS_NODE if needed)
- **AND** it correctly resolves the application path via `dirname` for symlink support
- **AND** it passes command-line arguments through to the Electron application
- **AND** it preserves macOS-specific launch behavior (e.g., single-process mode if required)

### Requirement: DMG Disk Image Creation
The package SHALL generate a macOS disk image (.dmg) with proper layout for easy installation.

#### Scenario: DMG is created with standard layout
- **WHEN** the package is built with DMG output enabled
- **THEN** a `.dmg` file is created containing the application bundle
- **AND** the DMG includes a symlink to `/Applications` for drag-and-drop installation
- **AND** the DMG is formatted as a read-only hybrid HFS+/UDF image
- **AND** the DMG contains the Kiro.app bundle at the root level

#### Scenario: DMG includes installation instructions
- **WHEN** the DMG is created
- **THEN** a `.background/` directory contains a background image (if available from resources)
- **AND** a `README.txt` or similar file with installation instructions is included
- **AND** window position and icon layout are configured for optimal presentation

#### Scenario: DMG artifact is accessible
- **WHEN** the flake package is built
- **THEN** the DMG is output as `$out/Kiro.dmg` or similar
- **AND** the DMG is available as a flake output artifact
- **AND** the DMG file size is reasonable for distribution (typically 300-600MB for Kiro)

### Requirement: Shell Completion Support on macOS
The package SHALL install shell completions for bash and zsh on macOS.

#### Scenario: Bash completion is installed
- **WHEN** the package is built
- **THEN** shell completions are installed to `$out/share/bash-completion/completions/kiro`
- **AND** macOS bash users can source the completion file from their dotfiles
- **AND** command completion for Kiro CLI arguments is available

#### Scenario: Zsh completion is installed
- **WHEN** the package is built
- **THEN** zsh completions are installed to `$out/share/zsh/site-functions/_kiro`
- **AND** macOS zsh users can access command completion
- **AND** the completion works in both bash-emulation and native zsh modes

### Requirement: Source Verification for macOS
The package SHALL verify the integrity of the downloaded macOS release using a cryptographic hash.

#### Scenario: Hash verification for macOS release
- **WHEN** the macOS release artifact is fetched with `pkgs.fetchurl`
- **THEN** the SHA256 hash is verified against the documented value
- **AND** the build fails immediately if the hash does not match
- **AND** the hash value is explicitly documented in the flake.nix source code
- **AND** different hashes are used for different architecture releases (x86_64-darwin vs aarch64-darwin)

### Requirement: Flake Output Structure for macOS
The package SHALL be exposed as a flake output with proper metadata for macOS.

#### Scenario: aarch64-darwin package is defined
- **WHEN** user runs `nix flake show` on a macOS system
- **THEN** `packages.aarch64-darwin.default` is defined and points to the macOS package
- **AND** `packages.aarch64-darwin.kiro-desktop` is available as a named output
- **AND** `packages.aarch64-darwin.dmg` is available as a DMG artifact output

#### Scenario: Package metadata is complete for macOS
- **WHEN** the macOS package derivation is defined
- **THEN** pname = "kiro-desktop-darwin" (or similar)
- **AND** version matches the official Kiro Desktop release version
- **AND** meta.description includes "macOS" or "aarch64-darwin"
- **AND** meta.homepage = "https://kiro.dev"
- **AND** meta.license includes AWS-IPL license information
- **AND** meta.platforms includes "aarch64-darwin"
- **AND** meta.mainProgram = "kiro" for `nix run` support on macOS

### Requirement: AI Features Support on macOS
The package SHALL preserve and enable ML models and vector database functionality for AI-powered features on macOS.

#### Scenario: ML models are accessible on macOS
- **WHEN** the application starts on macOS and uses AI features
- **THEN** the all-MiniLM-L6-v2 model (23M) is accessible in the application resources
- **AND** the quantized ONNX model (model_quantized.onnx) loads successfully on ARM64
- **AND** semantic embeddings and code search features work with ARM64 binaries

#### Scenario: Native dependencies load correctly on macOS
- **WHEN** AI features index code or perform semantic search on macOS
- **THEN** the LanceDB native addon loads correctly for aarch64-darwin
- **AND** ONNX runtime bindings (onnxruntime_binding.node) load ARM64 .dylib files
- **AND** vector similarity search completes without crashes on Apple Silicon

### Requirement: Platform-Specific Derivation Logic
The flake SHALL conditionally build the correct package variant based on the system architecture.

#### Scenario: aarch64-darwin uses Apple Silicon binaries
- **WHEN** the flake is evaluated on aarch64-darwin
- **THEN** the package fetches the aarch64-darwin compatible release
- **AND** NOT the x86_64-linux or x86_64-darwin variant
- **AND** the derivation does not cross-compile

#### Scenario: x86_64-linux continues to work unchanged
- **WHEN** the flake is evaluated on x86_64-linux
- **THEN** the existing Linux package derivation is used
- **AND** the new macOS packaging logic does NOT affect Linux builds
- **AND** the output `packages.x86_64-linux.default` points to the correct Linux package

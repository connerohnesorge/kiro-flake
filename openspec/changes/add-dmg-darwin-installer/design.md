## Context
Kiro Desktop is an AWS-powered IDE (VSCode fork) distributed as pre-built binaries. Currently, the flake only supports x86_64-linux. Extending to aarch64-darwin (Apple Silicon Macs) requires:
1. Fetching platform-specific binaries from the official release channel
2. Handling macOS app bundle (.app) structure
3. Creating a distributable DMG disk image
4. Configuring macOS-specific runtime environments

The implementation must avoid breaking existing Linux support and follow Nix conventions for multi-platform flakes.

## Goals / Non-Goals

### Goals
- Support aarch64-darwin as a first-class flake platform
- Generate installable DMG disk images for macOS distribution
- Maintain parity with Linux package capabilities (completions, metadata, AI features)
- Document any macOS-specific limitations or workarounds
- Ensure SHA256 verification for downloaded artifacts

### Non-Goals
- Code signing or notarization (will be noted as manual post-processing step)
- x86_64-darwin support (focus on Apple Silicon first)
- Universal binary creation (use pre-built aarch64-darwin only)
- MacApp Store distribution (out of scope)

## Decisions

### Decision 1: macOS Release Source
**What**: Fetch from official `prod.download.desktop.kiro.dev` endpoint, same as Linux.
**Why**: Consistency, single source of truth, official support channel.
**Alternatives**:
- GitHub releases: Less reliable API, version lag
- Custom mirror: Requires maintenance burden

### Decision 2: DMG vs App Bundle Only
**What**: Generate both the `.app` bundle (in $out) and a distributable `.dmg` artifact.
**Why**: Enables both Nix-based installation (`nix run`, `nix build`) AND easy manual installation (download DMG, drag to Applications).
**Alternatives**:
- Bundle only: Requires manual directory navigation in Nix store
- DMG only: Loses Nix composability

### Decision 3: Wrapper Script Approach
**What**: Create a minimal macOS wrapper that sets DYLD_LIBRARY_PATH and launches the app bundle.
**Why**: Respects macOS app bundle conventions, allows direct execution, handles symlinks correctly.
**Alternatives**:
- No wrapper: Direct app bundle execution (loses environment control, harder to patch)
- Mono wrapper: Single wrapper for all platforms (increases complexity, harder to maintain)

### Decision 4: Architecture-Specific Fetching
**What**: Use conditional expressions in flake.nix to fetch different URLs based on `system`.
**Why**: Matches Nix flake patterns, clean separation of concerns, no cross-compilation complexity.
**Alternatives**:
- Single tarball with both architectures: Bloats download, wastes bandwidth
- Build from source: Requires Xcode/build tools, slow, not guaranteed to work

## Risks / Trade-offs

### Risk 1: macOS Release Format Changes
**Mitigation**: Document the expected format (tarball or DMG) and set up CI/CD monitoring for format changes.

### Risk 2: Code Signing / Notarization
**Trade-off**: The flake does NOT code sign or notarize the DMG (requires Apple developer account and `codesign` tool).
**Mitigation**: Provide clear documentation on post-processing steps for production distribution.

### Risk 3: Framework Dependencies on macOS
**Trade-off**: Nix's approach to macOS frameworks is less mature than Linux.
**Mitigation**: Use `dyld` environment variables and bundle frameworks if needed; test thoroughly.

### Risk 4: DMG Size and Build Time
**Trade-off**: Creating a DMG adds build time and output size (~100-200MB).
**Mitigation**: Make DMG generation optional via a package variant; document expected size.

## Migration Plan

### Phase 1: Draft Implementation (This Change)
1. Create proposal and tasks
2. Implement basic aarch64-darwin package derivation
3. Test fetching and basic app bundle structure
4. Establish CI/CD support for macOS builds

### Phase 2: DMG & Polish (Future)
1. Implement DMG image generation
2. Add background image and visual polish
3. Test end-to-end installation workflow
4. Document code signing workarounds

### Phase 3: Production (Future)
1. Set up macOS CI runner in GitHub Actions
2. Automate notarization (requires Apple account)
3. Publish DMG artifacts to releases
4. Update README with installation instructions

### Rollback
If macOS support is no longer needed, simply remove the aarch64-darwin conditionals and DMG build logic from flake.nix. The Linux x86_64 package remains unaffected.

## Open Questions

1. **What is the exact format of macOS releases from Kiro?**
   - Are they `.tar.gz` files (like Linux) or native `.dmg` files?
   - What is the directory structure inside the tarball?
   - Where do AI models, extensions, and frameworks live?

2. **Do we support x86_64-darwin (Intel Macs)?**
   - For now, focus on aarch64-darwin (Apple Silicon). If x86_64-darwin support is needed, follow the same pattern.

3. **What post-processing is required for code signing?**
   - Document the manual `codesign` steps required for production DMG distribution.

4. **Should DMG generation be in the flake or external tooling?**
   - Preferred: In the flake for reproducibility.
   - Fallback: External script with clear Nix integration points.

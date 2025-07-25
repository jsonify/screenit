# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-25-fastlane-build-automation/spec.md

> Created: 2025-07-25
> Version: 1.0.0

## Technical Requirements

### Fastlane Configuration Structure
- **Fastfile** with macOS platform configuration and comprehensive lane definitions
- **Appfile** with screenit bundle identifier and developer account placeholders
- Global configuration constants (APP_NAME="screenit", BUNDLE_ID, DIST_DIR)
- Opt-out of analytics and documentation for performance

### Build Integration Requirements
- Integration with Xcode build system using xcodebuild commands
- Support for Debug and Release build configurations
- Universal binary support (Apple Silicon + Intel architecture)
- Intelligent code signing with adhoc fallback for development
- Build artifact management in dist/ directory

### Version Management Integration
- GitHub CLI integration for release synchronization
- Semantic versioning support with major.minor.patch format
- Info.plist version string synchronization with GitHub releases
- Automated version bumping with user confirmation
- Git tag management for beta and production releases

### Release Workflow Requirements
- Branch validation (staging for beta, main for production)
- Git status validation to prevent releases with uncommitted changes
- Automated tagging with timestamp for beta, semantic versioning for production
- GitHub release creation with build artifacts
- Build verification and signing status reporting

## Approach Options

**Option A: Shell Script Integration**
- Pros: Simple integration, reuses existing build scripts
- Cons: Less Fastlane-native, harder to extend

**Option B: Native Xcodebuild Integration** (Selected)
- Pros: Full Fastlane integration, better error handling, extensible
- Cons: More complex setup, requires Xcode build system knowledge

**Option C: Hybrid Approach**
- Pros: Best of both worlds, gradual migration
- Cons: Maintenance overhead, complexity

**Rationale:** Selected Option B for full Fastlane integration, better error handling, and extensibility. This provides the most maintainable solution and aligns with screenit's professional development goals.

## External Dependencies

- **Fastlane** - Build automation and deployment tool
  - **Purpose:** Core automation framework for build and release workflows
  - **Justification:** Industry standard for mobile/macOS build automation with excellent GitHub integration

- **GitHub CLI (gh)** - Command-line tool for GitHub operations
  - **Purpose:** Release creation, version synchronization, and repository management
  - **Justification:** Required for automated release workflows and version synchronization features

- **Xcode Command Line Tools** - Apple development tools
  - **Purpose:** xcodebuild, codesign, plutil, and other build utilities
  - **Justification:** Essential for macOS app building and code signing operations

## Implementation Architecture

### Lane Structure
```
build_debug          # Debug build with adhoc signing
build_release        # Release build with proper signing
launch              # Build debug and launch app
dev                 # Full development workflow
clean               # Clean build artifacts
verify_signing      # Code signing verification
info                # App bundle information
release             # Complete release workflow
beta                # Beta release creation
prod                # Production release creation
auto_beta           # Automated beta with tagging
auto_prod           # Automated production with tagging
bump_and_release    # Version bump and production release
validate_github_sync # GitHub version validation
sync_version_with_github # Version synchronization
```

### Build Configuration
- **Debug Configuration:** Fast builds with debugging symbols
- **Release Configuration:** Optimized builds with proper signing
- **Code Signing:** Developer ID for distribution outside App Store
- **Architecture:** Universal binary (arm64 + x86_64)

### Error Handling Strategy
- Comprehensive error checking with user-friendly messages
- Graceful fallbacks (adhoc signing when certificates unavailable)
- Validation of prerequisites (branch, git status, file existence)
- Clear guidance for error resolution

### Integration Points
- **Xcode Project:** screenit.xcodeproj with proper build settings
- **Info.plist:** Version string management and app metadata
- **GitHub Repository:** Release management and version tagging
- **File System:** Build artifact management in dist/ directory
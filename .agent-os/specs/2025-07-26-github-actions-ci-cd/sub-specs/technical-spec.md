# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-26-github-actions-ci-cd/spec.md

> Created: 2025-07-26
> Version: 1.0.0

## Technical Requirements

- GitHub Actions workflow with macos-latest runner supporting Xcode 15+
- Native xcodebuild commands for build, test, archive, and export operations
- Secure secrets management for code signing certificates and provisioning profiles
- Automated build artifact creation with universal binary (Intel + Apple Silicon) support
- Integration with GitHub releases API for automated distribution
- Build status reporting and failure notifications via GitHub checks API
- Command-line release workflow with semantic versioning (patch/minor/major)
- Automated version bumping with git tag integration and Xcode project updates

## Approach Options

**Option A: Simple Workflow with Manual Signing**
- Pros: Quick setup, minimal configuration, no certificate management
- Cons: Unsigned builds, security warnings for users, manual distribution

**Option B: Full CI/CD with Automated Signing and Notarization** (Selected)
- Pros: Production-ready builds, automated distribution, no security warnings
- Cons: Complex certificate setup, Apple Developer account required, longer build times

**Option C: Hybrid Approach with Optional Signing**
- Pros: Flexibility for different environments, gradual implementation
- Cons: Complex conditional logic, inconsistent build outputs

**Rationale:** Option B provides the most professional user experience and aligns with the open source project's goal of being a CleanShot X alternative. Proper code signing and notarization are essential for user trust and seamless installation.

## External Dependencies

- **GitHub Actions**: macOS runners with Xcode 15+ pre-installed
- **Justification**: Native GitHub integration, no additional infrastructure required

- **Apple Developer Account**: Required for code signing and notarization
- **Justification**: Essential for distribution outside App Store without security warnings

- **create-dmg (Optional)**: For creating installer disk images
- **Justification**: Professional distribution format, industry standard for macOS applications

## Release Workflow Architecture

### Command-Line Release Tool
The release workflow centers around a `release.sh` script that provides fastlane-style functionality:

```bash
./release.sh patch   # 1.0.0 → 1.0.1
./release.sh minor   # 1.0.1 → 1.1.0  
./release.sh major   # 1.1.0 → 2.0.0
```

**Workflow Steps:**
1. **Version Calculation**: Parse current git tag and increment based on type (patch/minor/major)
2. **Xcode Project Update**: Modify Info.plist CFBundleShortVersionString with new version
3. **Build Validation**: Run xcodebuild test to ensure code quality before release
4. **Git Operations**: Commit version changes, create git tag, and push to trigger CI/CD
5. **CI Trigger**: GitHub Actions automatically builds, signs, and creates release

### Version Bumping Script
A supporting `scripts/bump_version.sh` utility handles semantic version logic:
- Parses existing version tags (v1.2.3 format)
- Increments major, minor, or patch numbers according to semantic versioning
- Handles initial version creation (v0.1.0) for new projects
- Validates version format and provides error handling

### GitHub Actions Integration
The CI/CD pipeline detects new version tags and automatically:
- Builds release configuration with universal binary support
- Signs application with Developer ID certificate
- Submits for notarization with Apple's notary service
- Creates GitHub release with downloadable .dmg installer
- Updates release notes with auto-generated changelog
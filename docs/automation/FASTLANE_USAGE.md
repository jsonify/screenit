# Fastlane Build Automation for screenit

This document provides comprehensive usage instructions for the Fastlane build automation setup for the screenit macOS application.

## Overview

The Fastlane configuration provides automated build, testing, and release workflows for screenit, supporting both development and production workflows with GitHub integration.

## Prerequisites

- **Fastlane**: Install with `gem install fastlane` or `brew install fastlane`
- **Xcode**: Required for building macOS applications
- **GitHub CLI** (optional): For advanced GitHub integration features
- **Git**: Required for version control and release workflows

## Quick Start

```bash
# Install dependencies
gem install fastlane

# Build debug version
fastlane build_debug

# Build and launch debug version
fastlane launch

# Clean build artifacts
fastlane clean
```

## Available Lanes

### 🔨 Build Lanes

#### `fastlane build_debug`
Builds a debug version of screenit with development signing.

```bash
fastlane build_debug
```

**Output**: `dist/screenit-Debug.app`

#### `fastlane build_release`
Builds a release version of screenit with proper code signing.

```bash
fastlane build_release
```

**Output**: `dist/screenit-Release.app`

#### `fastlane clean`
Removes all build artifacts and recreates the dist directory.

```bash
fastlane clean
```

### 🚀 Development Lanes

#### `fastlane launch`
Builds debug version and automatically launches the application.

```bash
fastlane launch
```

#### `fastlane dev`
Complete development workflow with version validation and app launch.

```bash
fastlane dev
```

**Features**:
- Version sync validation
- Debug build
- Automatic app launch
- Development session feedback

### 🔍 Verification Lanes

#### `fastlane verify_signing`
Verifies code signing for the release build and displays signing information.

```bash
fastlane verify_signing
```

**Requirements**: Release build must exist (run `fastlane build_release` first)

#### `fastlane info`
Displays comprehensive information about the app bundle.

```bash
fastlane info
```

**Information displayed**:
- Bundle path and size
- Architecture (Intel/Apple Silicon)
- Version information
- Bundle metadata

### 🐙 GitHub Integration

#### `fastlane validate_github_sync`
Validates version synchronization between local Info.plist and GitHub releases.

```bash
fastlane validate_github_sync
```

**Features**:
- Compares local and remote versions
- Works with or without GitHub CLI
- Provides version mismatch warnings

#### `fastlane sync_version_with_github`
Synchronizes local version with the latest GitHub release.

```bash
fastlane sync_version_with_github
```

**Behavior**:
- Updates local Info.plist with GitHub release version
- Graceful fallback when GitHub CLI unavailable
- Preserves local version if no remote releases found

### 📦 Release Lanes

#### `fastlane beta`
Creates a beta release with timestamp tagging.

```bash
fastlane beta
```

**Features**:
- Validates branch (staging/main preferred)
- Checks for uncommitted changes
- Creates timestamped tag (e.g., `beta-20250125-143022`)
- Builds release version
- Creates GitHub release if CLI available

**Branch validation**: Prompts for confirmation if not on staging/main

#### `fastlane prod`
Creates a production release with semantic version tagging.

```bash
fastlane prod
```

**Features**:
- Requires main branch
- Strict git status validation
- Creates semantic version tag (e.g., `v1.0.0`)
- Builds release version
- Creates GitHub release as latest

**Requirements**: Must be on main branch with clean working directory

### 🤖 Automated Lanes

#### `fastlane auto_beta`
Fully automated beta release workflow.

```bash
fastlane auto_beta
```

**Workflow**:
1. Syncs version with GitHub
2. Creates beta release
3. Handles all validation automatically

#### `fastlane auto_prod`
Fully automated production release workflow.

```bash
fastlane auto_prod
```

**Workflow**:
1. Validates main branch
2. Syncs version with GitHub
3. Creates production release

#### `fastlane bump_and_release`
Increments version and creates production release.

```bash
# Patch version (1.0.0 -> 1.0.1)
fastlane bump_and_release type:patch

# Minor version (1.0.0 -> 1.1.0)
fastlane bump_and_release type:minor

# Major version (1.0.0 -> 2.0.0)
fastlane bump_and_release type:major
```

**Features**:
- Semantic version parsing and validation
- User confirmation for version changes
- Automatic Info.plist updates
- Git commit and push
- Production release creation

## Configuration

### Bundle Configuration

The Fastlane configuration uses these constants (defined in `fastlane/Fastfile`):

```ruby
APP_NAME = "screenit"
BUNDLE_ID = "com.screenit.screenit"
DIST_DIR = "dist"
SCHEME_NAME = "screenit"
PROJECT_NAME = "screenit"
```

### GitHub Integration Setup

For full GitHub integration features:

1. **Install GitHub CLI**:
   ```bash
   brew install gh
   ```

2. **Authenticate with GitHub**:
   ```bash
   gh auth login
   ```

3. **Configure repository**:
   ```bash
   gh repo create screenit --public
   git remote add origin https://github.com/yourusername/screenit.git
   ```

### Code Signing Setup

For release builds with proper code signing:

1. **Development Certificate**: Ensure you have a valid Apple Developer certificate
2. **Provisioning Profile**: Configure appropriate provisioning profiles
3. **Keychain Access**: Certificates should be available in Keychain

## Workflows

### Development Workflow

```bash
# Start development session
fastlane dev

# Make changes to code...

# Build and test
fastlane build_debug
fastlane verify_signing
fastlane info

# Clean when done
fastlane clean
```

### Release Workflow

#### Beta Release
```bash
# Ensure on staging or main branch
git checkout staging

# Create beta release
fastlane beta
```

#### Production Release
```bash
# Ensure on main branch with clean working directory
git checkout main
git status  # Should be clean

# Create production release
fastlane prod
```

#### Version Bump and Release
```bash
# Bump patch version and release
fastlane bump_and_release type:patch

# Or use automated workflow
fastlane auto_prod
```

## Error Handling

### Common Issues

#### Build Failures
- **Solution**: Check Xcode configuration and ensure build.sh script works
- **Debug**: Run `./build.sh` manually to isolate issues

#### Signing Issues
- **Solution**: Verify Developer Certificate in Keychain Access
- **Debug**: Run `fastlane verify_signing` for detailed signing info

#### GitHub Integration Issues
- **Solution**: Ensure GitHub CLI is authenticated (`gh auth status`)
- **Fallback**: All lanes work without GitHub CLI using local-only behavior

#### Version Format Issues
- **Solution**: Ensure Info.plist uses semantic versioning (X.Y.Z format)
- **Fix**: Update CFBundleShortVersionString to format like "1.0.0"

### Branch Validation Errors

#### Beta Release Branch Warning
```bash
⚠️  Beta releases should be created from 'staging' or 'main' branch
   Current branch: feature-branch
   Continue anyway? (y/N)
```

#### Production Release Branch Error
```bash
❌ Production releases must be created from 'main' branch
   Current branch: develop
```

### Working Directory Validation
```bash
❌ Working directory has uncommitted changes
   Please commit or stash changes before creating a release
```

## Testing

### Run All Tests
```bash
# Run comprehensive integration tests
./test_integration_complete.sh

# Run individual test suites
./test_fastlane_config.sh
./test_build_lanes.sh
./test_dev_workflow.sh
./test_github_integration.sh
./test_release_automation.sh
./test_advanced_automation.sh
```

### Test Coverage

- ✅ Configuration validation
- ✅ Build lane functionality
- ✅ Development workflow integration
- ✅ GitHub integration (with and without CLI)
- ✅ Release automation
- ✅ Advanced automation features
- ✅ Error handling and recovery
- ✅ End-to-end workflows

## Troubleshooting

### Performance Issues
- **Build Speed**: Use `fastlane build_debug` for faster development builds
- **Clean Builds**: Run `fastlane clean` to remove cached artifacts

### Integration Issues
- **GitHub CLI**: Verify authentication with `gh auth status`
- **Git Repository**: Ensure proper git remote configuration
- **Version Sync**: Use `fastlane validate_github_sync` to check sync status

### Advanced Usage

#### Custom Build Configurations
Modify the Fastfile to add custom build configurations or additional lanes as needed.

#### CI/CD Integration
The Fastlane configuration is designed to work in CI/CD environments:

```bash
# Example GitHub Actions usage
- name: Build Debug
  run: fastlane build_debug

- name: Run Tests
  run: ./test_integration_complete.sh

- name: Create Release
  run: fastlane auto_prod
```

## Support

For issues or questions:
1. Check this documentation
2. Run relevant test scripts to diagnose issues
3. Review Fastlane output for detailed error messages
4. Ensure all prerequisites are properly installed and configured

---

**Documentation Version**: 1.0.0  
**Last Updated**: 2025-07-25  
**Compatible with**: screenit 1.0.0+, Fastlane 2.0+
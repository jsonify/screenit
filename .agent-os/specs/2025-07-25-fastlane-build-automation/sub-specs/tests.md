# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-25-fastlane-build-automation/spec.md

> Created: 2025-07-25
> Version: 1.0.0

## Test Coverage

### Unit Tests

**Build Lane Validation**
- Test build_debug lane creates app bundle in correct location
- Test build_release lane applies proper build configuration
- Test adhoc signing fallback when certificates unavailable
- Test error handling for missing Xcode project or invalid configuration

**Version Management Tests**
- Test GitHub CLI integration for version retrieval
- Test Info.plist version string updates
- Test semantic version parsing and validation
- Test version synchronization logic

**File System Operations**
- Test clean lane removes all build artifacts
- Test dist/ directory creation and management
- Test app bundle validation and information extraction

### Integration Tests

**Development Workflow**
- Test complete dev lane execution (version sync → build → launch)
- Test launch lane builds and opens application successfully
- Test error recovery when version sync fails

**Release Workflow Integration**
- Test beta release workflow with staging branch validation
- Test production release workflow with main branch validation
- Test GitHub release creation with proper artifacts
- Test automated tagging with timestamp and semantic versioning

**Code Signing Integration**
- Test verify_signing lane with various signing states
- Test code signing detection and fallback behavior
- Test certificate information extraction and display

### Feature Tests

**Version Synchronization Scenarios**
- Test sync when GitHub CLI is available and authenticated
- Test fallback to git tags when GitHub CLI unavailable
- Test handling of version mismatches between Info.plist and GitHub
- Test automated version bump workflows

**Release Management Scenarios**
- Test release creation from clean git state
- Test error handling for uncommitted changes
- Test branch validation for beta vs production releases
- Test tag creation and GitHub release publishing

**Error Handling Scenarios**
- Test behavior when Xcode project is missing or corrupted
- Test handling of network failures during GitHub operations
- Test recovery from partial build failures
- Test graceful handling of permission issues

## Mocking Requirements

### GitHub CLI Integration
- **Mock Strategy:** Use test repository or stub GitHub CLI responses
- **Test Data:** Sample release data, version tags, authentication states
- **Purpose:** Test version synchronization without affecting production releases

### Xcode Build System
- **Mock Strategy:** Create minimal test project with known configuration
- **Test Data:** Valid/invalid project files, build settings, signing configurations
- **Purpose:** Test build automation without full screenit project dependency

### File System Operations
- **Mock Strategy:** Use temporary directories and controlled file system state
- **Test Data:** Sample app bundles, Info.plist files, build artifacts
- **Purpose:** Test file operations without affecting development environment

### Code Signing Operations
- **Mock Strategy:** Simulate various signing states and certificate availability
- **Test Data:** Sample codesign outputs, certificate information, validation results
- **Purpose:** Test signing verification without requiring actual certificates

## Test Environment Setup

### Prerequisites
- Test macOS environment with Xcode command line tools
- Fastlane installed and configured
- GitHub CLI available for integration tests
- Test Git repository with appropriate branch structure

### Test Data Management
- Sample screenit project structure with valid Info.plist
- Mock GitHub release data and version tags
- Test certificates and signing identities (if available)
- Controlled build artifact samples for validation testing

### Continuous Integration Considerations
- Tests should run in clean environment without external dependencies
- Mock external services (GitHub API, Apple services) appropriately
- Validate core functionality works across different macOS versions
- Ensure tests don't create persistent state or affect real repositories
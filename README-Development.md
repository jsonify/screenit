# screenit Development Guide

## 🔧 Development Build System

This project includes custom build scripts that maintain consistent code signing to preserve macOS permissions across builds.

### Quick Start

```bash
# Build and sign the app for development
./build-dev.sh

# Run the app
open dist/screenit.app
```

### Why Use Custom Build Scripts?

macOS resets screen recording permissions when an app's code signature changes between builds. Our build scripts:

1. **Use consistent signing identity** - Same certificate every time
2. **Include proper entitlements** - Screen capture permissions declared
3. **Add usage descriptions** - User-friendly permission prompts
4. **Create proper app bundles** - Complete macOS app structure

### Permission Persistence

✅ **With build scripts**: Permissions persist across builds
❌ **Without build scripts**: Must re-grant permissions every build

### Build Scripts Available

- **`build-dev.sh`** - Swift Package Manager based (recommended)
- **`build-xcode.sh`** - Xcode toolchain based (alternative)

### Files Modified for Permission Persistence

1. **`Info.plist`** - Added usage descriptions:
   - `NSScreenCaptureDescription`
   - `NSSystemAdministrationUsageDescription`

2. **`screenit.entitlements`** - Enhanced with:
   - Screen capture entitlement
   - File system access permissions
   - Sandbox exceptions for Desktop/Downloads

3. **Build scripts** - Consistent code signing with specific certificate

### First Time Setup

1. Grant permissions when prompted (first run only)
2. Use build scripts for all subsequent builds
3. Permissions will persist across rebuilds

### Troubleshooting

**If permissions still reset:**
- Ensure you're using the build scripts
- Check that the signing identity is available: `security find-identity -v -p codesigning`
- Try manually removing and re-adding the app in System Settings

**Build script errors:**
- Make sure scripts are executable: `chmod +x build-*.sh`
- Check for multiple developer certificates causing ambiguity

### Development Workflow

```bash
# Make code changes
vim screenit/...

# Quick rebuild (preserves permissions)
./build-dev.sh

# Test immediately
open dist/screenit.app
```

This workflow eliminates the need to constantly re-grant permissions during development!
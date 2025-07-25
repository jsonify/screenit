# screenit

An open source CleanShot X alternative for macOS 15+ built with SwiftUI and ScreenCaptureKit.

## Quick Start

### Build and Run
```bash
# Build debug version
fastlane build_debug

# Build and launch
fastlane launch

# Run complete development workflow  
fastlane dev
```

### Testing
```bash
# Run all tests
./scripts/test-runner.sh

# Run specific test categories
./scripts/test-runner.sh --fastlane-only
./scripts/test-runner.sh --integration-only
```

## Project Organization

This project follows Agent-OS standards for organization and automation:

- **📁 [Documentation](docs/README.md)** - Comprehensive guides organized by purpose
- **📁 [Tests](tests/)** - Organized test suites with common utilities  
- **📁 [Scripts](scripts/)** - Automation and utility scripts
- **📁 [Build System](docs/automation/FASTLANE_USAGE.md)** - Complete build automation

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for complete organization details.

## Phase 1 - Core Foundation ✅

This implementation provides:
- ✅ Basic SwiftUI Menu Bar Application with MenuBarExtra
- ✅ MenuBarManager for status item handling  
- ✅ Menu structure with placeholder actions
- ✅ Background operation configuration
- ✅ Basic unit tests for MenuBarManager

## Phase 1 - Screen Capture Engine ✅

Core screen capture functionality:
- ✅ CaptureEngine with singleton pattern and thread safety
- ✅ Authorization status management and permission handling
- ✅ Basic screen capture functionality (placeholder implementation)
- ✅ Error handling with comprehensive CaptureError enum
- ✅ Integration with MenuBarManager for capture workflow
- ✅ Image saving to Desktop with timestamped filenames
- ✅ Comprehensive test suite for CaptureEngine

## Features

- **Menu Bar Integration**: Native macOS menu bar app using SwiftUI MenuBarExtra
- **Keyboard Shortcuts**: 
  - Cmd+Shift+4: Capture Area
  - Cmd+Shift+H: Show History  
  - Cmd+,: Preferences
  - Cmd+Q: Quit
- **Background Operation**: Runs as LSUIElement (no dock icon)
- **Menu Actions**: Placeholder implementations for future features

## Building & Running

```bash
# Build the app
./build.sh

# Run the app
open screenit.app

# Or run directly
./screenit.app/Contents/MacOS/screenit
```

## Testing

```bash
# Run basic menu bar tests
swift run_tests.swift

# Run CaptureEngine tests
swift simple_test.swift
```

## Project Structure

```
screenit/
├── main.swift              # Main SwiftUI app and MenuBarManager
├── CaptureEngine.swift     # Core screen capture functionality
├── Info.plist             # App configuration (LSUIElement=true)
├── build.sh               # Build script for app bundle
├── run_tests.swift        # Basic unit tests
├── simple_test.swift      # CaptureEngine tests
└── README.md              # This file
```

## Next Steps

Ready for **Phase 1 Task 3**: Capture Overlay UI

The foundation is now in place for:
- ✅ Screen capture functionality (placeholder implementation)
- Capture overlay UI with crosshair cursor
- Area selection with drag-to-select
- Magnifier window with pixel coordinates

## Implementation Notes

- **Screen Capture**: Currently uses placeholder implementation due to ScreenCaptureKit framework availability
- **Authorization**: Simplified to always authorized for testing
- **Image Generation**: Creates test images that demonstrate the save workflow
- **Architecture**: Full CaptureEngine structure ready for ScreenCaptureKit integration

## Architecture

- **SwiftUI MenuBarExtra**: Modern macOS menu bar integration
- **MenuBarManager**: ObservableObject handling menu state and actions
- **Background App**: Configured as LSUIElement for menu bar only operation
- **Keyboard Shortcuts**: Built into SwiftUI menu structure
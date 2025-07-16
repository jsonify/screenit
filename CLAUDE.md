# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **screenit**, a macOS screenshot application built with SwiftUI and Xcode. It aims to be an open-source alternative to CleanShot X, targeting macOS 15+ (Sequoia and above). The project is currently in the initial development phase with basic SwiftUI setup.

## Development Commands

### Building the Project
```bash
# Build the project (from project root)
xcodebuild -scheme screenit -configuration Debug build

# Build for release
xcodebuild -scheme screenit -configuration Release build

# Clean build folder
xcodebuild -scheme screenit clean
```

### Running the Application
```bash
# Build and run (use Xcode for development)
open screenit.xcodeproj

# Command line build and run
xcodebuild -scheme screenit -configuration Debug build && open ./build/Debug/screenit.app
```

### Testing
```bash
# Run all tests (unit + UI tests)
xcodebuild -scheme screenit test

# Run unit tests only
xcodebuild -scheme screenitTests -destination 'platform=macOS' test

# Run UI tests only
xcodebuild -scheme screenitUITests -destination 'platform=macOS' test

# Run tests with code coverage
xcodebuild -scheme screenit -enableCodeCoverage YES test

# Run specific test class
xcodebuild -scheme screenit -destination 'platform=macOS' test -only-testing:screenitTests/CaptureEngineTests

# Run specific test method
xcodebuild -scheme screenit -destination 'platform=macOS' test -only-testing:screenitTests/CaptureEngineTests/testCaptureEngineInitialization

# Test in parallel (faster execution)
xcodebuild -scheme screenit -destination 'platform=macOS' test -parallel-testing-enabled YES

# Generate test report
xcodebuild -scheme screenit test -resultBundlePath TestResults.xcresult
```

## Architecture Overview

### Current Structure
- **screenit.xcodeproj**: Xcode project file with standard macOS app configuration
- **screenit/**: Main source directory containing:
  - `screenitApp.swift`: App entry point with basic SwiftUI App structure
  - `ContentView.swift`: Main view (currently placeholder with "Hello, world!")
  - `Assets.xcassets/`: App icons and visual assets
  - `screenit.entitlements`: App permissions and capabilities

### Planned Architecture (from PRD)
The project will evolve to include:

**Core Technologies**:
- **Screen Capture**: ScreenCaptureKit (macOS 12.3+)
- **UI Framework**: SwiftUI
- **Drawing/Annotations**: SwiftUI Canvas
- **Data Storage**: Core Data
- **Global Shortcuts**: Carbon/Cocoa event monitoring

**Planned Structure**:
```
screenit/
├── App/
│   ├── screenitApp.swift
│   └── ContentView.swift
├── Core/
│   ├── CaptureEngine.swift
│   ├── AnnotationEngine.swift
│   └── DataManager.swift
├── UI/
│   ├── CaptureOverlay/
│   ├── AnnotationTools/
│   ├── HistoryView/
│   └── MenuBar/
├── Models/
│   ├── CaptureItem.swift
│   └── Annotation.swift
└── Resources/
    ├── CoreData.xcdatamodeld
    └── Assets.xcassets
```

## Key Features (MVP Phase 1)

1. **Area Selection**: Crosshair cursor with magnifier, click-and-drag rectangle selection
2. **Annotation Tools**: Arrow, text, rectangle, highlight/blur tools
3. **Capture History**: Core Data backend storing 10 most recent captures
4. **Menu Bar App**: Global hotkeys and dropdown menu interface
5. **Preferences**: Hotkey customization, save locations, annotation defaults

## Development Guidelines

### Technology Stack
- **Target Platform**: macOS 15.0+ (Sequoia and above)
- **Development**: Swift 5.9+, Xcode 15+, SwiftUI
- **APIs**: ScreenCaptureKit, Core Data, Carbon (global shortcuts)
- **License**: MIT (open source)

### Key Implementation Areas
1. **Screen Capture Permissions**: Handle ScreenCaptureKit authorization
2. **Global Hotkeys**: Carbon/Cocoa event monitoring for system-wide shortcuts
3. **Overlay Windows**: Full-screen capture interface with SwiftUI
4. **Core Data Integration**: Persistent storage for capture history
5. **Menu Bar Integration**: NSStatusItem for system tray presence

### Current Development State
- Basic SwiftUI app scaffold in place
- Complete testing infrastructure with unit and UI tests
- Core Data in-memory testing setup
- Mock framework for ScreenCaptureKit testing
- Standard macOS app entitlements configured

## Testing Infrastructure

### Test Targets
- **screenitTests**: Unit tests for core functionality
- **screenitUITests**: UI integration tests

### Test Structure
```
screenitTests/
├── TestDataManager.swift          # Core Data in-memory testing utilities
├── CaptureEngineTests.swift       # Screen capture logic tests
├── DataManagerTests.swift         # Data persistence tests
├── ModelTests.swift               # Core Data model tests
└── MockScreenCaptureKit.swift     # Mock framework for ScreenCaptureKit

screenitUITests/
├── PermissionFlowUITests.swift    # Screen recording permission flow tests
└── CaptureOverlayUITests.swift    # Capture interface interaction tests
```

### Testing Guidelines
1. **Unit Tests**: Test individual components in isolation using mocks
2. **UI Tests**: Test user interactions and complete workflows
3. **Core Data**: Use in-memory store for fast, isolated testing
4. **Mocking**: Use MockScreenCaptureKit for testing without system dependencies
5. **Coverage**: Aim for >80% code coverage on core functionality

### Running Tests in Development
```bash
# Quick unit test run during development
xcodebuild -scheme screenitTests test

# Full test suite with coverage
xcodebuild -scheme screenit -enableCodeCoverage YES test

# Continuous testing (watch for file changes)
# Use Xcode's continuous testing or third-party tools
```

## Important Notes
- Comprehensive testing infrastructure is now in place
- Screen capture will require additional entitlements and user permissions
- Global hotkeys will need careful implementation for system-wide access
- Use TestDataManager for all Core Data-related unit tests
- Mock ScreenCaptureKit dependencies to avoid permission requirements in tests
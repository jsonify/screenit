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
# Run tests (when implemented)
xcodebuild -scheme screenit test

# Test specific destination
xcodebuild -scheme screenit -destination 'platform=macOS' test
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
- No screen capture functionality implemented yet
- No Core Data model defined yet
- Standard macOS app entitlements configured

## Important Notes
- This is the initial commit state - most functionality described in the PRD is not yet implemented
- The project structure will need significant expansion to match the planned architecture
- Screen capture will require additional entitlements and user permissions
- Global hotkeys will need careful implementation for system-wide access
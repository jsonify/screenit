# Technical Stack

> Last Updated: 2025-01-27
> Version: 1.0.0

## Core Technologies

### Application Framework
- **Framework:** SwiftUI + Swift 5.9+
- **Version:** Swift 5.9+ with SwiftUI
- **Platform:** macOS 15.0+ (Sequoia and above)

### Database System
- **Primary:** Core Data
- **Version:** Latest (macOS 15+ SDK)
- **Purpose:** Capture history, metadata, and annotation storage

## Development Stack

### Build Tools
- **Build System:** Xcode 15+
- **Package Manager:** Swift Package Manager (SPM)
- **macOS SDK:** macOS 15+ SDK

### Screen Capture Technology
- **Framework:** ScreenCaptureKit
- **Version:** macOS 12.3+ (optimized for macOS 15+)
- **Purpose:** High-performance screen capture with system integration

### UI Framework Details
- **Primary UI:** SwiftUI for all interface components
- **Drawing System:** SwiftUI Canvas for annotation tools
- **Menu Bar:** NSStatusItem with SwiftUI views
- **Global Shortcuts:** Carbon/Cocoa event monitoring APIs

## System Integration

### macOS APIs
- **ScreenCaptureKit:** Primary screen capture functionality
- **Core Data:** Persistent storage for captures and metadata
- **Carbon Events:** Global hotkey registration and monitoring
- **NSStatusItem:** Menu bar integration
- **SwiftUI Canvas:** Real-time annotation drawing

### Permissions Required
- **Screen Recording:** ScreenCaptureKit requires explicit permission
- **Accessibility:** Global hotkey monitoring (if needed)
- **File System:** Save captures to user-selected locations

## Architecture Patterns

### Application Architecture
- **Pattern:** MVVM (Model-View-ViewModel) with SwiftUI
- **Data Flow:** Unidirectional data flow with ObservableObject
- **State Management:** SwiftUI @State, @StateObject, and @EnvironmentObject

### Core Components
- **CaptureEngine:** ScreenCaptureKit wrapper and capture logic
- **AnnotationEngine:** Canvas-based drawing and annotation system  
- **DataManager:** Core Data stack and capture history management
- **GlobalHotkeyManager:** System-level keyboard shortcut handling
- **MenuBarManager:** Status bar item and menu management

## Distribution & Deployment

### Distribution Method
- **Primary:** Open source via GitHub repository
- **License:** MIT License
- **Build System:** GitHub Actions for CI/CD
- **Code Repository:** https://github.com/[username]/screenit

### Build Configuration
- **Minimum Deployment:** macOS 15.0
- **Architecture Support:** Apple Silicon + Intel (universal binary)
- **Signing:** Developer ID for distribution outside App Store
- **Packaging:** Standard .app bundle with embedded frameworks

## Development Dependencies

### Required Tools
- **Xcode:** 15.0+ (for macOS 15 SDK support)
- **macOS:** 15.0+ for development and testing
- **Swift:** 5.9+ (included with Xcode)

### Third-Party Dependencies
- **Approach:** Minimize external dependencies
- **Package Manager:** Swift Package Manager only
- **Current Dependencies:** None (using only system frameworks)

## Performance Considerations

### Memory Management
- **Images:** Efficient Core Data storage with thumbnail generation
- **Capture Buffer:** Temporary memory management during capture
- **History Limit:** Configurable retention (default 10 captures)

### System Resources
- **Background Usage:** Minimal when not actively capturing
- **Global Shortcuts:** Low-impact system event monitoring
- **Storage:** Compressed image data with metadata indexing
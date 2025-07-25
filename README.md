# screenit - Menu Bar Application

Basic SwiftUI menu bar application for macOS screen capture tool.

## Phase 1 - Core Foundation ✅

This implementation provides:
- ✅ Basic SwiftUI Menu Bar Application with MenuBarExtra
- ✅ MenuBarManager for status item handling  
- ✅ Menu structure with placeholder actions
- ✅ Background operation configuration
- ✅ Basic unit tests for MenuBarManager

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
# Run basic tests
swift run_tests.swift
```

## Project Structure

```
screenit/
├── main.swift              # Main SwiftUI app and MenuBarManager
├── Info.plist             # App configuration (LSUIElement=true)
├── build.sh               # Build script for app bundle
├── run_tests.swift        # Basic unit tests
└── README.md              # This file
```

## Next Steps

Ready for **Phase 1 Task 2**: ScreenCaptureKit Integration

The foundation is now in place for:
- Screen capture functionality (ScreenCaptureKit)
- Capture overlay UI
- Image save functionality  
- Global hotkey registration

## Architecture

- **SwiftUI MenuBarExtra**: Modern macOS menu bar integration
- **MenuBarManager**: ObservableObject handling menu state and actions
- **Background App**: Configured as LSUIElement for menu bar only operation
- **Keyboard Shortcuts**: Built into SwiftUI menu structure
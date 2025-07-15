# Screen Capture App - Product Requirements Document (MVP Phase 1)

## Project Overview

**Vision:** Create an open source CleanShot X alternative for macOS 15+, starting with core screenshot functionality and iterating toward advanced features.

**Target Platform:** macOS 15.0+ (Sequoia and above)  
**Development Framework:** SwiftUI + Xcode  
**License:** MIT  
**Distribution:** Open source via GitHub

## MVP Phase 1 - Core Features

### 1. Basic Area Selection
- **Crosshair cursor** with live pixel coordinates display
- **Magnifier window** showing:
  - Pixel-perfect zoom view
  - RGB color values of pixel under cursor
  - Coordinate position display
- **Click and drag rectangle selection**
- **Keyboard controls:**
  - Escape to cancel capture
  - Enter/Space to confirm selection
- **Visual feedback:**
  - Dimmed background outside selection
  - Selection area highlight with dimensions

### 2. Annotation Tools
**Core Tools:**
- Arrow tool (adjustable color, thickness)
- Text tool (font size, color selection)
- Rectangle outline (color, thickness options)
- Highlight/blur tool

**UI Features:**
- Simple color palette (6 predefined colors)
- Undo/redo functionality from launch
- Tool selection via toolbar or keyboard shortcuts

### 3. Capture History
- **Storage:** Core Data backend for images and metadata
- **Capacity:** 10 most recent captures (configurable later)
- **Thumbnail grid view** accessible from menu bar
- **Metadata tracking:**
  - Timestamp
  - Image dimensions
  - File size
- **Actions per capture:**
  - Copy to clipboard
  - Save to Desktop (quick action)
  - Save as... (with file dialog)
  - Delete from history

### 4. Menu Bar Application
**Menu Bar Icon:**
- Show/hide based on user preference
- Visual indicator for app status

**Dropdown Menu Options:**
- "Capture Area" - triggers area selection
- "Show History" - opens capture history window
- "Preferences" - opens settings
- "Quit" - exits application

### 5. Keyboard Shortcuts (Global Hotkeys)
- **Primary capture:** Cmd+Shift+4 (configurable)
- **Show history:** Cmd+Shift+H (configurable)
- **Quick actions during capture:**
  - Escape: Cancel
  - Enter/Space: Confirm selection
  - Tab: Cycle through annotation tools

### 6. Preferences
- Hotkey customization
- Menu bar visibility toggle
- Default save location
- History retention count
- Annotation tool defaults (color, thickness)

## Technical Architecture

### Core Technologies
- **Screen Capture:** ScreenCaptureKit (macOS 12.3+)
- **UI Framework:** SwiftUI
- **Drawing/Annotations:** SwiftUI Canvas
- **Data Storage:** Core Data
- **Global Shortcuts:** Carbon/Cocoa event monitoring

### Data Model (Core Data)
```
CaptureItem
- id: UUID
- timestamp: Date
- imageData: Data
- thumbnailData: Data
- width: Int32
- height: Int32
- fileSize: Int64
- annotations: [Annotation]

Annotation
- id: UUID
- type: String (arrow, text, rectangle, highlight)
- position: CGPoint
- properties: JSON (color, thickness, text content)
- captureItem: CaptureItem
```

### Project Structure
```
ScreenCapture/
├── App/
│   ├── ScreenCaptureApp.swift
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

## User Flow - MVP

### Primary Capture Flow
1. User triggers capture (hotkey or menu)
2. Screen overlay appears with crosshair cursor
3. User sees magnifier with RGB values and coordinates
4. User clicks and drags to select area
5. Selection confirmed → annotation mode
6. User adds annotations (optional)
7. User saves (quick to Desktop or Save As...)
8. Capture added to history automatically

### History Access Flow
1. User clicks menu bar → "Show History"
2. Grid view shows 10 most recent captures
3. User can copy, save, or delete items
4. Double-click to re-open for editing

## Success Metrics (MVP)
- Successfully captures screen areas with pixel accuracy
- Annotations work smoothly without lag
- History persists between app sessions
- Global hotkeys work reliably
- App performs well on macOS 15+

## Future Phases (Post-MVP)

### Phase 2 - Enhanced Capture
- Scrolling capture (primary goal)
- Enhanced annotation tools
- Export format options
- Improved history management

### Phase 3 - Advanced Features
- Screen recording
- OCR integration
- Advanced editing tools
- Plugin system

### Phase 4 - Polish & Community
- Performance optimizations
- Accessibility features
- Community contributions
- Documentation

## Development Considerations

### Learning Path
1. Start with basic SwiftUI + menu bar app
2. Implement ScreenCaptureKit integration
3. Build capture overlay UI
4. Add Core Data storage
5. Implement global shortcuts
6. Add annotation tools
7. Polish and testing

### Technical Challenges
- Global hotkey registration
- Screen capture permissions
- Overlay window management
- Performance optimization for large images
- Core Data migration strategy

### Open Source Strategy
- Public GitHub repository
- Clear contribution guidelines
- Issue templates and project boards
- Regular milestone releases
- Community feedback integration

## Dependencies & Requirements

**macOS APIs:**
- ScreenCaptureKit
- SwiftUI
- Core Data
- Carbon (for global shortcuts)

**Third-party Libraries:** TBD (minimize dependencies)

**Development Tools:**
- Xcode 15+
- Swift 5.9+
- macOS 15+ SDK

---

*This PRD will evolve as development progresses and community feedback is incorporated.*
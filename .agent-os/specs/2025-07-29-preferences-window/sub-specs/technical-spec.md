# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-29-preferences-window/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Technical Requirements

- SwiftUI-based tabbed preferences window with native macOS appearance and behavior
- Core Data integration for persistent storage of all preference values with immediate save capability
- Global hotkey recording and validation system with conflict detection and system shortcut awareness
- File system integration for save location selection with bookmark security scoping for sandboxed apps
- Real-time preview system for annotation defaults with canvas rendering of color and thickness changes
- Launch agent integration using SMLoginItemSetEnabled or modern ServiceManagement framework for login items
- Menu bar visibility control with dynamic NSStatusItem show/hide functionality

## Approach Options

**Option A: Single Window with Tab View**
- Pros: Standard macOS pattern, familiar UX, easy navigation, consistent with system preferences
- Cons: Limited space for complex settings, potential crowding on smaller screens
- Implementation: TabView with enum-based tab selection and @State management

**Option B: Multi-Window Settings (Selected)**
- Pros: Dedicated space for each category, better organization, professional appearance, extensible design
- Cons: More complex window management, potential user confusion
- Implementation: NavigationSplitView with sidebar navigation and detail views

**Option C: Single Scrollable View**
- Pros: Simple implementation, all settings visible, no navigation complexity
- Cons: Poor UX on large settings lists, doesn't follow macOS patterns, poor scalability

**Rationale:** Option B provides the best user experience for a professional tool while maintaining scalability for future settings categories. The NavigationSplitView approach aligns with modern macOS design patterns and provides clear visual hierarchy.

## External Dependencies

- **No External Libraries Required** - Using only native SwiftUI and system frameworks
- **Justification:** Maintains the project's minimal dependency philosophy while leveraging optimized system APIs for preferences management, hotkey handling, and file system integration

## Implementation Architecture

### PreferencesManager (Core Data + ObservableObject)
- Singleton pattern for app-wide preference access
- @Published properties for real-time UI updates
- Core Data persistence with immediate save operations
- Default value management and validation

### PreferencesWindow (SwiftUI Window)
- WindowGroup-based preferences window with fixed size
- NavigationSplitView for sidebar and detail pane layout
- Keyboard shortcuts for window management (Cmd+, to open)

### Settings Categories
1. **General Tab**: Save locations, history retention, basic behavior
2. **Hotkeys Tab**: Global shortcut recording and management
3. **Annotations Tab**: Default colors, thickness, tool presets
4. **Advanced Tab**: Launch at login, menu bar options, performance settings

### Hotkey Recording System
- Carbon Events integration for global shortcut capture
- Modifier key + key combination validation
- Conflict detection with system shortcuts and other applications
- Visual feedback with hotkey display component

### File Location Management
- NSOpenPanel integration for folder selection
- Security-scoped bookmarks for sandboxed file access
- Quick access to common locations (Desktop, Documents, Pictures)
- Path validation and permission checking
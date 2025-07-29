# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-07-29-preferences-window/spec.md

> Created: 2025-07-29
> Status: Ready for Implementation

## Tasks

- [x] 1. Core Data Schema and PreferencesManager Implementation
  - [x] 1.1 Write tests for UserPreferences Core Data entity creation and validation
  - [x] 1.2 Create UserPreferences Core Data entity with all required properties
  - [x] 1.3 Implement Core Data model version migration for UserPreferences
  - [x] 1.4 Write tests for PreferencesManager singleton pattern and Core Data integration
  - [x] 1.5 Create PreferencesManager class with ObservableObject and @Published properties
  - [x] 1.6 Implement default value management and validation logic
  - [x] 1.7 Verify all tests pass for Core Data and PreferencesManager functionality

- [ ] 2. Hotkey Recording and Management System
  - [ ] 2.1 Write tests for HotkeyRecorder validation and conflict detection
  - [ ] 2.2 Create HotkeyRecorder component for capturing keyboard combinations
  - [ ] 2.3 Implement hotkey validation and system conflict detection
  - [ ] 2.4 Write tests for hotkey serialization and global registration
  - [ ] 2.5 Implement hotkey serialization to JSON and GlobalHotkeyManager integration
  - [ ] 2.6 Create visual hotkey display component with real-time feedback
  - [ ] 2.7 Verify all tests pass for hotkey recording and management

- [ ] 3. Preferences Window UI Foundation
  - [ ] 3.1 Write tests for PreferencesWindow navigation and tab management
  - [ ] 3.2 Create SwiftUI PreferencesWindow with WindowGroup integration
  - [ ] 3.3 Implement NavigationSplitView with sidebar and detail pane layout
  - [ ] 3.4 Write tests for preference binding and real-time updates
  - [ ] 3.5 Create preference category views (General, Hotkeys, Annotations, Advanced)
  - [ ] 3.6 Implement keyboard shortcuts and window management behavior
  - [ ] 3.7 Verify all tests pass for window foundation and navigation

- [ ] 4. File Location Management and UI Controls
  - [ ] 4.1 Write tests for FileLocationManager bookmark handling and validation
  - [ ] 4.2 Create FileLocationManager for save location selection and persistence
  - [ ] 4.3 Implement NSOpenPanel integration with security-scoped bookmarks
  - [ ] 4.4 Write tests for save location UI components and user interactions
  - [ ] 4.5 Create save location picker UI with quick access shortcuts
  - [ ] 4.6 Implement path validation and permission checking with user feedback
  - [ ] 4.7 Verify all tests pass for file location management functionality

- [ ] 5. Annotation Defaults Configuration Interface
  - [ ] 5.1 Write tests for annotation default validation and preview rendering
  - [ ] 5.2 Create annotation defaults UI with color pickers and thickness sliders
  - [ ] 5.3 Implement real-time preview canvas for annotation changes
  - [ ] 5.4 Write tests for color validation and default value management
  - [ ] 5.5 Implement color validation and hex string conversion utilities
  - [ ] 5.6 Create annotation preset management with save/load functionality
  - [ ] 5.7 Verify all tests pass for annotation defaults and preview system

- [ ] 6. System Integration Features and Final Integration
  - [ ] 6.1 Write tests for launch at login and menu bar visibility controls
  - [ ] 6.2 Implement SMLoginItemSetEnabled integration for launch at login
  - [ ] 6.3 Create menu bar visibility toggle with NSStatusItem management
  - [ ] 6.4 Write tests for end-to-end preferences workflow and persistence
  - [ ] 6.5 Integrate preferences window with existing menu bar application
  - [ ] 6.6 Implement preference change propagation to all app components
  - [ ] 6.7 Verify all tests pass and complete integration testing
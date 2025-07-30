# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-07-29-preferences-redesign/spec.md

> Created: 2025-07-29
> Status: Ready for Implementation

## Tasks

- [ ] 1. Core Data Schema Extension and Migration
  - [ ] 1.1 Write tests for new UserPreferences properties and validation
  - [ ] 1.2 Add new preference properties to UserPreferences Core Data model (referencing `/Users/jsonify/Desktop/mocks` for exact field requirements)
  - [ ] 1.3 Update UserPreferences.createWithDefaults() with new property defaults
  - [ ] 1.4 Implement Core Data migration for schema changes
  - [ ] 1.5 Update PreferencesManager to handle new properties with proper validation
  - [ ] 1.6 Verify all tests pass and Core Data integration works

- [ ] 2. Sidebar Navigation System Implementation
  - [ ] 2.1 Write tests for sidebar navigation state management
  - [ ] 2.2 Create PreferencesSidebarView component matching `/Users/jsonify/Desktop/mocks/preferences_general.png` sidebar design
  - [ ] 2.3 Implement sidebar icons and navigation states for General, Wallpaper, Shortcuts, Quick Access, Recording, Screenshots, Annotate, Cloud, Advanced, About
  - [ ] 2.4 Add proper selection highlighting and keyboard navigation support
  - [ ] 2.5 Integrate sidebar with main content area switching logic
  - [ ] 2.6 Verify all tests pass and navigation works smoothly

- [ ] 3. General Preferences Panel Redesign
  - [ ] 3.1 Write tests for General panel UI controls and data binding
  - [ ] 3.2 Redesign GeneralPreferencesView to match `/Users/jsonify/Desktop/mocks/preferences_general.png` exactly
  - [ ] 3.3 Implement startup options (Start at login checkbox)
  - [ ] 3.4 Add sounds section with Play sounds toggle and Shutter sound dropdown
  - [ ] 3.5 Implement menu bar Show icon toggle
  - [ ] 3.6 Add export location dropdown and Desktop icons "Hide while capturing" option
  - [ ] 3.7 Create after capture action matrix with Screenshot/Recording/Action columns and checkboxes for each action type
  - [ ] 3.8 Verify all tests pass and General panel matches mock design

- [ ] 4. Screenshots Preferences Panel Implementation
  - [ ] 4.1 Write tests for Screenshots panel controls and preference binding
  - [ ] 4.2 Create new ScreenshotsPreferencesView matching `/Users/jsonify/Desktop/mocks/preferences_screenshots.png`
  - [ ] 4.3 Add file format dropdown (PNG with additional options)
  - [ ] 4.4 Implement Retina "Scale Retina screenshots to 1x" checkbox
  - [ ] 4.5 Add color management "Convert to sRGB profile" checkbox
  - [ ] 4.6 Implement frame "Add 1px border to all screenshots" checkbox
  - [ ] 4.7 Add background dropdown with "None" option and explanation text
  - [ ] 4.8 Create self-timer interval dropdown (5 Seconds with options)
  - [ ] 4.9 Add cursor "Show on screenshots" checkbox with explanation text
  - [ ] 4.10 Implement freeze screen checkbox
  - [ ] 4.11 Add crosshair mode dropdown (Disabled) with "Show magnifier" checkbox
  - [ ] 4.12 Include PixelSnap promotion section as shown in mock
  - [ ] 4.13 Verify all tests pass and Screenshots panel matches mock exactly

- [ ] 5. Annotate Preferences Panel Redesign
  - [ ] 5.1 Write tests for Annotate panel settings and functionality
  - [ ] 5.2 Redesign AnnotationPreferencesView to match `/Users/jsonify/Desktop/mocks/preferences_annotate.png`
  - [ ] 5.3 Add arrow tool "Inverse arrow direction" checkbox with explanation
  - [ ] 5.4 Implement pencil tool "Smooth drawing" checkbox
  - [ ] 5.5 Add background tool "Remember if tool was opened" checkbox
  - [ ] 5.6 Create shadow "Draw shadow on objects" checkbox
  - [ ] 5.7 Implement canvas "Automatically expand" checkbox with explanation
  - [ ] 5.8 Add accessibility "Show color names" checkbox
  - [ ] 5.9 Create window section with "Always on top" and "Show Dock icon" checkboxes
  - [ ] 5.10 Verify all tests pass and Annotate panel matches mock design

- [ ] 6. Quick Access Preferences Panel Creation
  - [ ] 6.1 Write tests for Quick Access panel functionality
  - [ ] 6.2 Create new QuickAccessPreferencesView matching `/Users/jsonify/Desktop/mocks/preferences_quick-access.png`  
  - [ ] 6.3 Add position on screen dropdown (Left with options)
  - [ ] 6.4 Implement multi-display "Move to active screen" checkbox with explanation
  - [ ] 6.5 Create overlay size slider control
  - [ ] 6.6 Add auto-close section with Enable checkbox and Action/Interval dropdowns
  - [ ] 6.7 Implement drag & drop "Close after dragging" checkbox with explanation
  - [ ] 6.8 Add cloud upload "Close after uploading" checkbox
  - [ ] 6.9 Create save button behavior dropdown with explanation
  - [ ] 6.10 Verify all tests pass and Quick Access panel matches mock

- [ ] 7. Advanced Preferences Panel Enhancement
  - [ ] 7.1 Write tests for Advanced panel expanded functionality
  - [ ] 7.2 Redesign AdvancedPreferencesView to match `/Users/jsonify/Desktop/mocks/preferences_advanced.png`
  - [ ] 7.3 Add file name section with Edit button and "Ask for name after every capture" checkbox
  - [ ] 7.4 Implement "Add '@2x' suffix to Retina screenshots" checkbox with explanation
  - [ ] 7.5 Create copy to clipboard dropdown (File & Image default) with explanation
  - [ ] 7.6 Add pinned screenshots section with Rounded corners, Shadow, and Border checkboxes
  - [ ] 7.7 Implement keep history radio buttons (Never, 1 day, 3 days, 1 week, 1 month) with explanation
  - [ ] 7.8 Add All-In-One "Remember last selection" checkbox
  - [ ] 7.9 Create text recognition section with language dropdown and Keep line breaks/Detect links checkboxes
  - [ ] 7.10 Add API section with "Allow applications to control CleanShot" checkbox and explanation
  - [ ] 7.11 Include Dialogs section with "Reset All Warning Dialogs" button
  - [ ] 7.12 Verify all tests pass and Advanced panel matches mock design

- [ ] 8. Main Preferences Window Integration and Polish
  - [ ] 8.1 Write tests for complete preferences window functionality
  - [ ] 8.2 Update main PreferencesView to use sidebar navigation instead of segmented control
  - [ ] 8.3 Implement proper window sizing and layout to accommodate sidebar design
  - [ ] 8.4 Add smooth transitions between preference panels
  - [ ] 8.5 Ensure all data binding works correctly with PreferencesManager
  - [ ] 8.6 Test preference persistence and loading across app restarts
  - [ ] 8.7 Verify window management and memory handling
  - [ ] 8.8 Cross-reference all implemented panels against `/Users/jsonify/Desktop/mocks` for design accuracy
  - [ ] 8.9 Verify all tests pass and complete preferences system works correctly
# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-29-preferences-redesign/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Test Coverage

### Unit Tests

**PreferencesManager Extensions**
- Test new preference property getters and setters
- Test default value assignment for new properties  
- Test Core Data binding preservation during UI changes
- Test preference validation for new enum-based settings
- Test migration compatibility with existing preference data

**UserPreferences Model Tests**
- Test new Core Data properties can be saved and loaded
- Test default value creation includes all new properties
- Test property validation for dropdown selections and numeric ranges
- Test resetToDefaults() includes new preference properties

**UI Component Tests**
- Test sidebar navigation state management
- Test proper selection highlighting and transitions
- Test content view switching between preference panels
- Test data binding between UI controls and PreferencesManager

### Integration Tests

**Preferences Window Integration**
- Test complete preferences window loads with sidebar navigation
- Test navigation between all preference panels works correctly
- Test preference changes are persisted to Core Data immediately
- Test window state management and proper cleanup on close

**Core Data Integration**
- Test new preference properties are properly saved to database
- Test migration from old to new schema works without data loss
- Test concurrent access to preferences during UI updates
- Test error handling when Core Data context is unavailable

**UI State Synchronization**
- Test preference changes in one panel reflect in other panels if applicable
- Test real-time updates when preferences change from external sources
- Test proper refresh of UI controls when preferences are reset to defaults

### Feature Tests

**General Preferences Panel**
- Test startup options toggle properly
- Test sound settings and shutter sound selection
- Test menu bar icon visibility toggle
- Test export location selection and custom folder picker
- Test post-capture action matrix functionality

**Screenshots Preferences Panel**
- Test file format selection (PNG/JPEG) saves correctly
- Test retina scaling option toggles properly
- Test color management setting persistence
- Test frame border option functionality
- Test background preset selection
- Test self-timer interval setting and validation
- Test cursor display options
- Test freeze screen toggle
- Test crosshair mode selection and magnifier toggle

**Annotate Preferences Panel**
- Test arrow tool inversion setting
- Test pencil tool smooth drawing toggle
- Test background tool memory setting
- Test shadow drawing option
- Test canvas auto-expand functionality
- Test accessibility color names option
- Test window always-on-top and dock icon settings

**Quick Access Preferences Panel**
- Test overlay position selection and validation
- Test multi-display move-to-active-screen option
- Test overlay size slider functionality and bounds
- Test auto-close enable/disable and configuration options
- Test drag & drop close-after-dragging setting
- Test cloud upload close-after-uploading option
- Test save button behavior selection

**Advanced Preferences Panel**
- Test file naming pattern selection
- Test ask-for-name-after-capture toggle
- Test retina suffix addition option
- Test clipboard copy mode selection
- Test pinned screenshot appearance options (corners, shadow, border)
- Test history retention period selection
- Test All-In-One remember-last-selection option
- Test text recognition language selection and options
- Test API control allow/disallow setting

### Mocking Requirements

**File System Operations**
- Mock folder selection dialogs for custom export locations
- Mock file system access validation for save locations
- Mock bookmark data creation and resolution for security-scoped access

**Core Data Context**
- Mock Core Data save operations for error condition testing
- Mock context availability for offline testing scenarios
- Mock migration scenarios for schema update testing

**System Integration**
- Mock system preferences for launch-at-login functionality
- Mock sound system for shutter sound testing
- Mock screen capture permissions for preference validation

### Performance Tests

**UI Responsiveness**
- Test sidebar navigation responds within 100ms
- Test preference panel switching completes within 200ms
- Test large preference datasets don't cause UI lag
- Test memory usage stays within reasonable bounds during extended use

**Data Persistence Performance**
- Test preference saves complete within 500ms
- Test batch preference updates don't block UI thread
- Test Core Data query performance for preference loading
- Test migration performance with existing user data

### Error Handling Tests

**Invalid Preference Values**
- Test handling of invalid enum selections
- Test numeric preference bounds validation
- Test string preference format validation
- Test graceful degradation when preferences are corrupted

**System Integration Failures**
- Test behavior when Core Data is unavailable
- Test handling of file system permission errors
- Test recovery from preference loading failures
- Test UI state consistency during error conditions
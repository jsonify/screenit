# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-29-preferences-window/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Test Coverage

### Unit Tests

**PreferencesManager**
- Test singleton pattern ensures single instance across app lifecycle
- Test default values are applied correctly on first launch
- Test Core Data persistence saves and retrieves all preference values correctly
- Test validation logic prevents invalid values (negative history limits, invalid colors)
- Test preference change notifications trigger @Published updates for UI binding

**HotkeyRecorder**
- Test hotkey combination parsing and validation with various modifier combinations
- Test conflict detection identifies system shortcuts and existing application shortcuts
- Test hotkey serialization and deserialization maintains accuracy across app restarts
- Test invalid hotkey combinations are rejected with appropriate user feedback

**FileLocationManager** 
- Test save location bookmark creation and resolution with security scoping
- Test default location handling when custom location becomes unavailable
- Test permission validation for selected folders before saving preferences
- Test path display formatting for user-friendly location representation

**AnnotationDefaults**
- Test color string validation accepts valid hex colors and rejects invalid formats
- Test thickness and size validation enforces reasonable minimum and maximum values
- Test default value application when existing preferences are corrupted or missing

### Integration Tests

**Preferences Window**
- Test window opens from menu bar command with correct initial state
- Test all tabs load properly with current preference values displayed
- Test preference changes are immediately reflected in other parts of the application
- Test window keyboard shortcuts (Cmd+W to close, tab navigation) work correctly

**Hotkey Integration**
- Test new hotkey assignments replace old ones without conflicts
- Test hotkey changes are immediately active without requiring app restart
- Test system hotkey conflicts prevent registration and show appropriate error messages
- Test hotkey restoration works correctly after system reboot or app restart

**File System Integration**
- Test folder selection dialog respects sandbox permissions and security scoping
- Test save location changes are immediately used for new captures
- Test bookmark resolution handles moved or renamed folders gracefully
- Test permissions are maintained across app launches and system updates

### Feature Tests

**Complete Preferences Workflow**
- User opens preferences, changes hotkey, save location, and annotation defaults, then creates new capture to verify all changes are applied
- User sets launch at login preference and verifies behavior after system restart
- User modifies history retention limit and confirms older captures are cleaned up appropriately

**Preference Persistence Workflow**
- Configure all preferences to non-default values, quit and restart app, verify all settings are preserved correctly
- Test preferences survive app crashes and corrupted data scenarios with graceful fallback to defaults
- Verify preferences export/import capability if implemented for backup purposes

### Mocking Requirements

**File System Operations**
- Mock NSOpenPanel for testing folder selection without user interaction
- Mock bookmark resolution to test various file system scenarios (moved folders, permission changes)
- Mock security-scoped resource access for testing sandboxed environments

**System Integration**
- Mock SMLoginItemSetEnabled for testing launch at login without modifying system state
- Mock Carbon Events for hotkey testing without interfering with system shortcuts
- Mock NSStatusItem for testing menu bar visibility changes in headless test environment

**Core Data Context**
- Mock NSManagedObjectContext for testing preferences persistence without requiring full Core Data stack
- Mock save operations to test error handling and rollback scenarios
- Mock fetch operations to test various data states (empty, corrupted, multiple instances)
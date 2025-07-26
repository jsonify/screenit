# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-25-emergency-debugging-spec/spec.md

> Created: 2025-07-25
> Version: 1.0.0

## Test Coverage

### Unit Tests

**MenuBarManager.saveImageToDesktop**
- Test Desktop directory URL resolution success and failure cases
- Test CGImageDestination creation with various image inputs
- Test file write permissions and access to Desktop directory
- Test timestamp filename generation and uniqueness
- Test error handling for all failure scenarios

**File System Validation**
- Test Desktop directory existence verification
- Test file existence verification after save operations
- Test write permission checking for Desktop directory
- Test file size and metadata validation

### Integration Tests

**Complete Image Save Workflow**
- Test full capture → save → verify workflow with actual CGImage
- Test save operation timing and async behavior
- Test multiple consecutive save operations
- Test save operation during various app states

**Permission Integration**
- Test save operation with various macOS permission states
- Test save behavior in sandboxed vs non-sandboxed environments
- Test Desktop directory access across different user account types

### Manual Testing Scenarios

**Debug Log Verification**
- Execute `fastlane dev` and verify debug logs appear in Console.app
- Capture screenshot and verify all debug messages appear in correct order
- Verify actual file creation on Desktop after successful debug logging
- Test error scenarios and verify appropriate error logging

**File System State Testing**
- Manually verify files exist on Desktop after save operations
- Check file sizes and metadata match expected values
- Verify file permissions and ownership are correct
- Test with various Desktop directory states (full disk, permissions changes)

### Mocking Requirements

**For Unit Tests:**
- Mock FileManager for directory resolution failure testing
- Mock CGImageDestination for creation and finalization failure testing
- Mock file system permissions for access denied scenarios

**No Mocking for Integration Tests:**
- Use real file system operations to verify actual behavior
- Use real Desktop directory for true environment testing
- Use actual CGImage objects from test captures
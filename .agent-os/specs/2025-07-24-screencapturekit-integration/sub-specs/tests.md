# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-24-screencapturekit-integration/spec.md

> Created: 2025-07-24
> Version: 1.0.0

## Test Coverage

### Unit Tests

**CaptureEngine**
- Test permission status checking and caching
- Test capture area validation (valid/invalid rectangles)  
- Test image processing pipeline (SCScreenshot → CGImage → PNG)
- Test filename generation with timestamp formatting
- Test error handling for various failure scenarios
- Test singleton pattern and thread safety

**Permission Management**
- Test authorization status detection
- Test permission request flow initiation
- Test handling of granted/denied/undetermined states
- Test permission status change notifications

**File Operations**
- Test Desktop directory path resolution
- Test PNG file creation and validation
- Test filename collision handling
- Test disk space availability checks

### Integration Tests

**Screen Capture Workflow**
- End-to-end capture from menu selection to file creation
- Permission request flow with system dialog interaction
- Capture area selection and validation
- Image quality verification of captured content
- File system integration and save location verification

**Menu Bar Integration**
- Test capture initiation from menu bar interface
- Test user feedback and status updates during capture
- Test error message display in menu bar context
- Test capture availability based on permission status

**System Integration**
- Test behavior when screen recording permission changes
- Test performance under various system load conditions
- Test multi-monitor environment handling
- Test compatibility with other screen capture applications

### Mocking Requirements

- **ScreenCaptureKit Framework**: Mock SCScreenshotManager for unit testing capture logic without actual screen access
- **File System Operations**: Mock file writing operations to test error conditions and validate file handling logic
- **Permission System**: Mock AVCaptureDevice.authorizationStatus to test different permission states
- **System Dialogs**: Mock permission request dialogs to test user interaction flows

## Test Scenarios

### Happy Path Testing
1. **First Launch**: App requests permission → user grants → capture succeeds → file saves to Desktop
2. **Subsequent Use**: Permission already granted → immediate capture → successful save
3. **Menu Bar Workflow**: User clicks menu → selects capture → area selection → image saved

### Error Path Testing
1. **Permission Denied**: User denies permission → clear error message → guidance to System Preferences  
2. **Capture Failure**: ScreenCaptureKit fails → retry mechanism → fallback error handling
3. **File Save Error**: Desktop not writable → alternative location → user notification
4. **System Resource**: Low memory → graceful degradation → appropriate error message

### Edge Case Testing
1. **Multi-Monitor**: Capture across monitor boundaries → correct screen detection
2. **Display Changes**: Monitor disconnection during capture → graceful handling
3. **Concurrent Captures**: Multiple simultaneous capture requests → proper queuing
4. **Large Areas**: Very large capture regions → memory management → performance validation
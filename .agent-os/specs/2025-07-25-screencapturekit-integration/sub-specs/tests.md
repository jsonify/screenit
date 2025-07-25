# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-25-screencapturekit-integration/spec.md

> Created: 2025-07-25
> Version: 1.0.0

## Test Coverage

### Unit Tests

**CaptureEngine (Enhanced)**
- Test authorization status detection and updates
- Test async capture methods with mock ScreenCaptureKit responses
- Test error handling for various failure scenarios (no permission, no displays, capture failure)
- Test image processing pipeline from sample buffer to CGImage
- Test file saving functionality with different output formats
- Test memory management and resource cleanup

**SCCaptureManager**
- Test permission request flow and status validation
- Test content discovery with mock SCShareableContent
- Test capture stream configuration and execution
- Test sample buffer processing and image conversion
- Test error propagation and recovery mechanisms

**MenuBarManager Integration**
- Test triggerCapture() integration with real CaptureEngine
- Test error state handling and user feedback
- Test capture success notifications and status updates

### Integration Tests

**ScreenCaptureKit Permission Flow**
- Test permission request dialog presentation
- Test permission status detection across app launches
- Test capture functionality enabling/disabling based on permissions
- Test System Preferences integration for manual permission granting

**Full Capture Workflow**
- Test complete capture flow from menu trigger to file save
- Test area selection rectangle processing and coordinate validation
- Test captured image quality and format correctness
- Test file naming convention and Desktop save location

**Error Handling Integration**
- Test permission denied scenario with user guidance
- Test no displays available error handling
- Test capture failure recovery and user notifications
- Test file system error handling (permissions, disk space)

### Feature Tests

**Screen Capture Functionality**
- Test full screen capture using ScreenCaptureKit
- Test area capture with various rectangle sizes and positions
- Test multi-display environment handling
- Test capture quality and color accuracy validation

**File Management**
- Test PNG file creation with proper metadata
- Test timestamp-based filename generation
- Test Desktop save location and file permissions
- Test file overwrite prevention and unique naming

### Mocking Requirements

**ScreenCaptureKit Framework**
- **Mock SCShareableContent:** Simulate available displays and windows for testing without actual screen access
- **Mock SCStream:** Test capture stream configuration and execution without creating real streams
- **Mock CMSampleBuffer:** Simulate captured frame data for image processing pipeline testing
- **Mock Authorization States:** Test all permission scenarios without requiring actual system permission dialogs

**File System Operations**
- **Mock Desktop Directory:** Test file saving without cluttering actual Desktop during development
- **Mock File Write Operations:** Validate PNG creation and metadata without actual file I/O
- **Mock Disk Space Scenarios:** Test error handling for insufficient storage space

**System Integration**
- **Mock System Preferences:** Test permission guidance without opening actual System Preferences
- **Mock Display Configuration:** Test multi-monitor scenarios with simulated display layouts
- **Mock Memory Pressure:** Test resource cleanup under simulated low memory conditions

## Performance Testing

**Memory Usage Validation**
- Test memory consumption during large area captures
- Test proper resource cleanup after capture operations
- Test memory leak detection during repeated captures

**Capture Speed Benchmarking**
- Test capture latency from trigger to completion
- Test image processing pipeline performance
- Test file save operation timing

**System Resource Impact**
- Test CPU usage during capture operations
- Test system responsiveness during capture
- Test background memory footprint when idle
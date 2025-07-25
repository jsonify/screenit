# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-24-screencapturekit-integration/spec.md

> Created: 2025-07-24
> Version: 1.0.0

## Technical Requirements

- **ScreenCaptureKit Integration**: Import and configure ScreenCaptureKit framework for screen capture operations
- **Permission System**: Implement screen recording permission checks with AVCaptureDevice authorization status
- **Capture API**: Use SCScreenshotManager for basic rectangular area capture functionality
- **Image Processing**: Convert SCScreenshot content to CGImage and export as PNG format
- **File Management**: Generate timestamped filenames and save to user's Desktop directory
- **Error Handling**: Provide meaningful error messages for permission denied, capture failed, and file save errors
- **Menu Bar Integration**: Connect capture functionality to existing MenuBarManager interface

## Approach Options

**Option A: SCScreenshotManager with Direct Area Capture**
- Pros: Simple API, handles most screen capture logic, good performance
- Cons: Limited customization options, requires macOS 14+ for some features

**Option B: SCStreamConfiguration with Stream Capture** 
- Pros: More control over capture process, supports advanced features like cursor inclusion
- Cons: More complex implementation, higher resource usage, overkill for basic capture

**Option C: Legacy NSScreen with CGImage** (Selected for fallback only)
- Pros: Available on older macOS versions, simple implementation
- Cons: Deprecated approach, missing modern privacy controls, poor performance

**Rationale:** Option A (SCScreenshotManager) provides the best balance of simplicity and functionality for our MVP needs. We'll use Option B for future enhancements requiring stream-based capture.

## External Dependencies

- **ScreenCaptureKit** - Apple's native framework for screen capture
- **Justification:** Required for modern macOS screen capture with proper privacy controls and performance

- **AVFoundation** - For authorization status checking
- **Justification:** Provides standard authorization patterns for screen recording permissions

No third-party dependencies required - using only Apple system frameworks aligned with our minimal dependency approach.

## Implementation Architecture

### Core Components

**CaptureEngine Class**
- Singleton manager for all screen capture operations
- Handles ScreenCaptureKit configuration and lifecycle
- Manages permission states and authorization flow
- Provides async capture methods with error handling

**Permission Management**
- Check current authorization status on app launch
- Present permission request dialog when needed
- Handle permission denied scenarios with user guidance
- Cache permission status to avoid repeated checks

**Capture Workflow**
1. Verify screen recording permission
2. Present area selection interface (basic rectangle selection)
3. Capture selected area using SCScreenshotManager
4. Process captured image and convert to PNG
5. Generate timestamped filename
6. Save to Desktop directory
7. Provide user feedback on success/failure

### Error Handling Strategy

- **Permission Denied**: Show alert with instructions to enable in System Preferences
- **Capture Failed**: Retry mechanism with fallback error message
- **File Save Failed**: Alternative save location or user notification
- **Framework Unavailable**: Graceful degradation with informative message
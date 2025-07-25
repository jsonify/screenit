# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-25-screencapturekit-integration/spec.md

> Created: 2025-07-25
> Version: 1.0.0

## Technical Requirements

- **ScreenCaptureKit Framework**: Import and integrate ScreenCaptureKit for macOS 15+ compatibility
- **Permission Handling**: Implement screen recording authorization request and status validation
- **Content Discovery**: Use SCShareableContent to discover available displays and windows
- **Stream Configuration**: Configure SCStreamConfiguration for high-quality still image capture
- **Image Processing**: Handle captured sample buffers and convert to CGImage/NSImage formats
- **File System Integration**: Save captured images as PNG files with descriptive timestamps
- **Error Recovery**: Comprehensive error handling with user-facing error messages
- **Memory Management**: Efficient handling of large image buffers and proper resource cleanup
- **Thread Safety**: Proper async/await usage for UI updates and capture operations

## Approach Options

**Option A: Direct ScreenCaptureKit Implementation**
- Pros: Maximum control over capture process, optimal performance, latest API features
- Cons: More complex implementation, requires deeper ScreenCaptureKit knowledge

**Option B: Wrapper-Based Abstraction** (Selected)
- Pros: Cleaner separation of concerns, easier testing, gradual ScreenCaptureKit adoption
- Cons: Additional abstraction layer, potential performance overhead

**Rationale:** Option B provides better maintainability and allows for easier testing while preserving the flexibility to optimize performance later. The abstraction layer also makes it easier to add additional capture sources in future phases.

## ScreenCaptureKit Integration Architecture

### Core Components

**SCCaptureManager**: Wrapper class managing ScreenCaptureKit lifecycle
- Handles authorization requests and status monitoring
- Manages display content discovery and refresh
- Configures and executes capture streams
- Converts sample buffers to usable image formats

**Permission States**: Enum defining authorization status
- `notDetermined`: Initial state, permission not requested
- `denied`: User explicitly denied screen recording access
- `authorized`: Permission granted and validated
- `restricted`: System policy prevents access

**Capture Pipeline**: Async workflow for image capture
1. Validate authorization status
2. Discover available content (displays/windows)
3. Configure capture stream for target area
4. Execute single-frame capture
5. Process sample buffer to CGImage
6. Apply any necessary transformations
7. Return processed image data

### Technical Implementation Details

**Framework Integration**:
```swift
import ScreenCaptureKit

@available(macOS 12.3, *)
class SCCaptureManager: ObservableObject {
    private var availableContent: SCShareableContent?
    private var captureStream: SCStream?
}
```

**Permission Management**:
- Use SCShareableContent.getExcludingDesktopWindows() to trigger permission dialog
- Monitor authorization status changes via SCShareableContent availability
- Provide user guidance for manual permission granting in System Preferences

**Capture Configuration**:
- SCStreamConfiguration with high-quality settings (width/height, pixel format)
- Single-frame capture mode rather than continuous streaming
- Appropriate color space handling for accurate color reproduction

**Image Processing**:
- CMSampleBuffer to CVPixelBuffer conversion
- CVPixelBuffer to CGImage transformation
- PNG encoding for file output with metadata preservation

## External Dependencies

**ScreenCaptureKit Framework** - Apple's native screen capture framework
- **Justification:** Required for modern macOS screen capture with proper permission handling and optimal performance. Replaces deprecated CGWindowListCreateImage APIs.
- **Version:** macOS 12.3+ (optimized for macOS 15+ features)
- **Usage:** Core capture functionality, permission management, content discovery

**No Third-Party Dependencies** - Maintains project philosophy of using only Apple frameworks
- **Rationale:** ScreenCaptureKit provides all necessary functionality for this phase
- **Future Consideration:** Core Data will be added in Phase 4 for capture history
# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-07-25-screencapturekit-integration/spec.md

> Created: 2025-07-25
> Status: Ready for Implementation

## Tasks

- [x] 1. Set up ScreenCaptureKit Framework and Permissions
  - [x] 1.1 Write tests for screen recording permission management
  - [x] 1.2 Add ScreenCaptureKit framework import and entitlements
  - [x] 1.3 Implement permission check and request functionality
  - [x] 1.4 Create user-friendly permission UI flow
  - [x] 1.5 Verify all tests pass for permission handling

- [ ] 2. Create SCCaptureManager Wrapper
  - [ ] 2.1 Write tests for SCCaptureManager initialization and configuration
  - [ ] 2.2 Create SCCaptureManager.swift with ScreenCaptureKit integration
  - [ ] 2.3 Implement display detection and content filter setup
  - [ ] 2.4 Add async/await capture configuration methods
  - [ ] 2.5 Verify all tests pass for capture manager

- [ ] 3. Implement Basic Area Capture Functionality
  - [ ] 3.1 Write tests for area capture with mock screen coordinates
  - [ ] 3.2 Create capture session configuration for rectangular areas
  - [ ] 3.3 Implement sample buffer to CGImage conversion pipeline
  - [ ] 3.4 Add capture execution with proper error handling
  - [ ] 3.5 Verify all tests pass for area capture logic

- [ ] 4. Replace Mock CaptureEngine with Real Implementation
  - [ ] 4.1 Write tests for updated CaptureEngine with ScreenCaptureKit
  - [ ] 4.2 Update CaptureEngine.swift to use SCCaptureManager instead of mock
  - [ ] 4.3 Implement real screen coordinate to capture area mapping
  - [ ] 4.4 Add proper memory management for captured images
  - [ ] 4.5 Verify all tests pass for real capture engine

- [ ] 5. Integrate with MenuBarManager and File Saving
  - [ ] 5.1 Write tests for menu bar trigger to capture workflow
  - [ ] 5.2 Update MenuBarManager.triggerCapture() to use real CaptureEngine
  - [ ] 5.3 Implement PNG file saving to Desktop with timestamp filenames
  - [ ] 5.4 Add user feedback for successful captures and errors
  - [ ] 5.5 Test complete workflow from menu bar click to saved file
  - [ ] 5.6 Verify all tests pass for integrated capture workflow
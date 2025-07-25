# Spec Requirements Document

> Spec: ScreenCaptureKit Integration
> Created: 2025-07-25
> Status: Planning

## Overview

Implement ScreenCaptureKit framework integration to replace the current mock implementation with real screen capture functionality for macOS 15+. This provides the foundational screen capture capability that users will trigger from the menu bar's "Capture Area" option.

## User Stories

### Core Screen Capture Functionality

As a professional developer, I want to capture specific areas of my screen using native macOS ScreenCaptureKit, so that I can create pixel-perfect screenshots for documentation and bug reports.

**Workflow:** User clicks "Capture Area" from menu bar → system requests screen recording permission if needed → user selects screen area → image is captured using ScreenCaptureKit → image is saved to Desktop with timestamp filename.

### Permission Management

As a macOS user, I want the app to properly handle screen recording permissions, so that I understand what access is required and can grant permissions when prompted.

**Workflow:** App detects missing screen recording permission → displays user-friendly permission request → opens System Preferences if needed → validates permission status → enables/disables capture functionality accordingly.

### Error Handling

As a user, I want clear error messages when screen capture fails, so that I understand what went wrong and how to resolve issues.

**Workflow:** Capture operation fails → app identifies specific error type → displays appropriate user message → logs technical details → provides recovery suggestions when possible.

## Spec Scope

1. **ScreenCaptureKit Framework Integration** - Replace mock CGImage generation with real ScreenCaptureKit implementation
2. **Screen Recording Permission Management** - Handle macOS permission requests and validation properly
3. **Area Selection Capture** - Implement basic rectangular area capture functionality
4. **Image File Saving** - Save captured images to Desktop with timestamp-based filenames
5. **MenuBarManager Integration** - Connect real capture functionality to existing menu bar trigger
6. **Error Handling and Logging** - Comprehensive error management with user-friendly messages

## Out of Scope

- Visual capture overlay with crosshair cursor (Phase 2)
- Live coordinate display and magnifier window (Phase 2)
- Annotation tools and drawing capabilities (Phase 3)
- Capture history and Core Data persistence (Phase 4)
- Advanced capture modes like scrolling capture (Future phases)
- Global hotkey registration beyond menu bar shortcuts

## Expected Deliverable

1. **Functional ScreenCaptureKit Integration** - CaptureEngine uses real ScreenCaptureKit APIs instead of mock CGImage generation
2. **Working Area Capture** - Users can capture rectangular screen areas and save PNG files to Desktop
3. **Proper Permission Handling** - App gracefully requests and validates screen recording permissions with user feedback

## Spec Documentation

- Technical Specification: @.agent-os/specs/2025-07-25-screencapturekit-integration/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-07-25-screencapturekit-integration/sub-specs/tests.md
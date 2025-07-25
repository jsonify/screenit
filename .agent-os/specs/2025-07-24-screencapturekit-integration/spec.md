# Spec Requirements Document

> Spec: ScreenCaptureKit Integration
> Created: 2025-07-24
> Status: Planning

## Overview

Implement basic screen capture functionality using Apple's ScreenCaptureKit framework to enable users to capture screen areas and save images to disk. This establishes the core capture engine that will power the screenit application.

## User Stories

### Basic Screen Capture

As a macOS user, I want to capture a selected area of my screen using the menu bar application, so that I can save important information or content for later use.

**Workflow**: User clicks "Capture Area" from menu bar → system requests screen recording permission (if needed) → user selects screen area → image is captured and saved to Desktop → user receives confirmation of successful capture.

### Permission Handling

As a first-time user, I want the application to gracefully handle screen recording permissions, so that I understand what access is needed and can easily grant the required permissions.

**Workflow**: App detects missing screen recording permission → presents clear explanation of why permission is needed → guides user to System Preferences → retries capture after permission is granted → provides helpful error messages if permission is denied.

## Spec Scope

1. **ScreenCaptureKit Framework Integration** - Set up and configure ScreenCaptureKit for basic screen capture operations
2. **Screen Recording Permission Management** - Handle macOS permission requests with clear user guidance
3. **Basic Area Selection** - Enable user to select rectangular screen areas for capture
4. **Image Processing Pipeline** - Convert captured content to standard image format (PNG)
5. **File Save Workflow** - Save captured images to Desktop with timestamp naming

## Out of Scope

- Advanced capture overlay UI with crosshair cursor (Phase 2)
- Annotation tools and drawing capabilities (Phase 3)
- Capture history and persistence (Phase 4)
- Magnifier window and RGB color sampling (Phase 2)
- Custom save locations and preferences (Phase 5)

## Expected Deliverable

1. **Functional Screen Capture** - User can successfully capture rectangular screen areas through menu bar interface
2. **Permission Handling** - Application properly requests and handles screen recording permissions with user-friendly messaging
3. **File Output** - Captured images are saved as PNG files to Desktop with descriptive filenames

## Spec Documentation

- Tasks: @.agent-os/specs/2025-07-24-screencapturekit-integration/tasks.md
- Technical Specification: @.agent-os/specs/2025-07-24-screencapturekit-integration/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-07-24-screencapturekit-integration/sub-specs/tests.md
# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-07-27-post-capture-preview/spec.md

> Created: 2025-07-27
> Status: Ready for Implementation

## Tasks

- [ ] 1. Create PostCapturePreviewManager Core Component
  - [ ] 1.1 Write tests for PostCapturePreviewManager initialization and basic functionality
  - [ ] 1.2 Create PostCapturePreviewManager class with ObservableObject protocol
  - [ ] 1.3 Implement preview window lifecycle management (create, show, hide, cleanup)
  - [ ] 1.4 Add timer system for auto-dismiss functionality with configurable timeout
  - [ ] 1.5 Implement screen positioning calculations with multi-monitor support
  - [ ] 1.6 Verify all PostCapturePreviewManager tests pass

- [ ] 2. Build PostCapturePreviewView SwiftUI Interface  
  - [ ] 2.1 Write tests for PostCapturePreviewView rendering and user interactions
  - [ ] 2.2 Create SwiftUI view with image thumbnail display and aspect ratio handling
  - [ ] 2.3 Implement action buttons (Annotate/Dismiss) with proper styling and accessibility
  - [ ] 2.4 Add countdown timer visual indicator with smooth animations
  - [ ] 2.5 Implement keyboard event handling (Enter/Escape key support)
  - [ ] 2.6 Verify all PostCapturePreviewView tests pass

- [ ] 3. Create PostCapturePreviewWindow NSPanel Integration
  - [ ] 3.1 Write tests for NSPanel configuration and window management behavior
  - [ ] 3.2 Create custom NSPanel subclass with appropriate window level and styling
  - [ ] 3.3 Implement intelligent positioning logic for bottom-right corner placement
  - [ ] 3.4 Configure window properties (frameless, non-resizable, floating behavior)
  - [ ] 3.5 Add proper event handling and responder chain management
  - [ ] 3.6 Verify all PostCapturePreviewWindow tests pass

- [ ] 4. Integrate Preview System with Existing Capture Workflow
  - [ ] 4.1 Write integration tests for capture-to-preview and preview-to-annotation workflows
  - [ ] 4.2 Modify MenuBarManager.handleAreaSelected() to show preview instead of immediate annotation
  - [ ] 4.3 Update AnnotationCaptureManager to support intermediate preview state
  - [ ] 4.4 Implement preview action handlers (annotate button → annotation interface, dismiss button → cleanup)
  - [ ] 4.5 Add proper window lifecycle management to prevent memory leaks
  - [ ] 4.6 Verify all integration tests pass and existing capture workflow remains functional

- [ ] 5. Polish Animations and User Experience
  - [ ] 5.1 Write tests for animation timing and visual transitions
  - [ ] 5.2 Implement smooth fade-in animation with scale effect for preview appearance
  - [ ] 5.3 Add fade-out animation for dismissal and auto-timeout scenarios
  - [ ] 5.4 Fine-tune animation timing and easing for native macOS feel
  - [ ] 5.5 Test accessibility compliance and reduced motion preferences
  - [ ] 5.6 Verify all animation and UX tests pass
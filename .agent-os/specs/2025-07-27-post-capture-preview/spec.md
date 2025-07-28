# Spec Requirements Document

> Spec: Post-Capture Preview Feature
> Created: 2025-07-27
> Status: Planning

## Overview

Implement a CleanShot X style post-capture preview system that displays a scaled-down thumbnail of captured screenshots in the bottom-right corner of the screen. Users can interact with this preview to proceed with annotation or dismiss the capture, providing better workflow control and reducing accidental captures.

## User Stories

### Quick Preview and Dismiss

As a power user, I want to see a preview of my screenshot immediately after capture, so that I can quickly verify it captured what I intended and either proceed with annotation or dismiss it if it's incorrect.

**Detailed Workflow:** User triggers capture → selects area → screenshot is taken → small preview appears in bottom-right corner with thumbnail image, "Annotate" button, and "Dismiss" button. User can click either button or wait for auto-dismiss timeout.

### Annotation Workflow Control

As a professional developer, I want control over whether to annotate my screenshots, so that I can save time on simple captures that don't need annotation while still having the option available.

**Detailed Workflow:** After capture, preview appears with clear action buttons. Clicking "Annotate" opens the full annotation interface. Clicking "Dismiss" or waiting for timeout saves the screenshot without annotation workflow.

### Seamless Integration

As a design professional, I want the preview to feel native to macOS and integrate smoothly with my existing workflow, so that it enhances rather than disrupts my screenshot process.

**Detailed Workflow:** Preview appears with system-appropriate styling, smooth animations, and positioning that doesn't interfere with other applications. Keyboard shortcuts (Enter/Escape) work as expected for power users.

## Spec Scope

1. **Post-Capture Preview Window** - SwiftUI floating window displaying scaled screenshot thumbnail
2. **Bottom-Right Positioning** - Intelligent positioning in screen corner with multi-monitor support
3. **Action Buttons** - "Annotate" and "Dismiss" buttons with clear visual hierarchy
4. **Auto-Dismiss Timer** - Configurable timeout (default 6 seconds) with visual countdown indicator
5. **Integration with Existing Flow** - Seamless insertion between capture completion and annotation workflow
6. **Keyboard Support** - Enter key to annotate, Escape key to dismiss for power users
7. **Animation System** - Smooth fade-in/fade-out transitions matching macOS design language

## Out of Scope

- Preview editing capabilities (cropping, basic adjustments)
- Multi-screenshot preview management
- Preview window customization/theming beyond system defaults
- Integration with screenshot history during preview phase
- Advanced preview positioning options (user-configurable corners)

## Expected Deliverable

1. **Preview Interface** - Users can see a thumbnail preview immediately after screenshot capture in the bottom-right corner
2. **Action Controls** - Users can click "Annotate" to proceed to annotation mode or "Dismiss" to cancel and delete the screenshot
3. **Auto-Dismiss** - Preview automatically disappears after 6 seconds if no user interaction, saving screenshot without annotation

## Spec Documentation

- Tasks: @.agent-os/specs/2025-07-27-post-capture-preview/tasks.md
- Technical Specification: @.agent-os/specs/2025-07-27-post-capture-preview/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-07-27-post-capture-preview/sub-specs/tests.md
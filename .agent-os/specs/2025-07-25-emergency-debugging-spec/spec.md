# Spec Requirements Document

> Spec: Emergency Debugging Infrastructure for Image Save Workflow
> Created: 2025-07-25
> Status: Planning

## Overview

Implement comprehensive debugging and logging infrastructure for the screenit app's image saving workflow to identify why saved images are not appearing on Desktop despite successful code execution.

## User Stories

### Primary Investigation Story

As a developer debugging the screenit app, I want to see detailed logging and verification of every step in the image saving process, so that I can identify why images aren't appearing on Desktop despite the saveImageToDesktop function completing without errors.

**Detailed workflow analysis needed:**
1. Verify the saveImageToDesktop function is actually being called
2. Confirm Desktop directory resolution and write permissions  
3. Validate CGImageDestination creation and finalization success
4. Check actual file system state after save operations
5. Identify any permission, timing, or file system issues

### Debug Verification Story

As a developer testing the fix, I want to see real-time logging in both the app logs and system console, so that I can verify the complete image saving workflow is functioning correctly from capture through file system persistence.

**Debug workflow requirements:**
1. Console logging visible during fastlane dev execution
2. File system verification showing actual saved files
3. Permission status reporting for Desktop directory access
4. Error detection for all failure points in the save pipeline

## Spec Scope

1. **Comprehensive Function Call Tracing** - Add entry/exit logging to saveImageToDesktop and all related functions
2. **Desktop Directory Validation** - Verify Desktop URL resolution, existence, and write permissions
3. **CGImageDestination Debug Logging** - Log creation success/failure, finalization results, and error states
4. **File System State Verification** - Check actual file existence after save operations complete
5. **Permission and Security Audit** - Verify app has proper file system access permissions
6. **Performance and Timing Analysis** - Track save operation timing to identify async issues

## Out of Scope

- UI changes for debugging (debugging via console logs only)
- New save location functionality (focus on Desktop-only debugging)
- Image format changes (PNG debugging only)
- Core Data integration (Phase 1 debugging only)

## Expected Deliverable

1. **Comprehensive logging** showing successful image save to Desktop with file verification
2. **Clear error identification** if save process is failing at any specific step
3. **Permission status reporting** confirming app can write to Desktop directory

## Spec Documentation

- Tasks: @.agent-os/specs/2025-07-25-emergency-debugging-spec/tasks.md
- Technical Specification: @.agent-os/specs/2025-07-25-emergency-debugging-spec/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-07-25-emergency-debugging-spec/sub-specs/tests.md
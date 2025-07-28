# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-27-post-capture-preview/spec.md

> Created: 2025-07-27
> Version: 1.0.0

## Technical Requirements

### SwiftUI Preview Window
- Floating NSWindow with SwiftUI content hosting controller
- Frameless window style with rounded corners and subtle shadow
- Window level set above normal applications but below system alerts
- Minimum size 280x200 points, maximum size 320x240 points
- Non-resizable, non-miniaturizable window configuration

### Image Display and Scaling
- Display captured CGImage scaled to fit preview dimensions
- Maintain aspect ratio with letterboxing if necessary
- Maximum thumbnail size 200x150 points with 20pt padding
- High-quality scaling using SwiftUI's .aspectRatio(.fit) modifier
- Support for both portrait and landscape screenshot orientations

### Positioning and Multi-Monitor Support
- Default position: 20 points from right edge, 20 points from bottom edge
- Screen edge detection using NSScreen.main and NSScreen.screens
- Intelligent repositioning if preview would be off-screen
- Multi-monitor awareness - position relative to screen containing cursor
- Avoid covering dock, menu bar, or other system UI elements

### Timer System and Auto-Dismiss
- Configurable timeout duration (default 6 seconds)
- Visual countdown indicator using SwiftUI ProgressView or custom ring
- Timer pause/resume capability when user hovers over preview
- Immediate timer cancellation when user interacts with buttons
- Smooth fade-out animation when auto-dismiss triggers

### Action Button Interface
- Two primary action buttons: "Annotate" and "Dismiss"
- SwiftUI Button components with system-appropriate styling
- "Annotate" button as primary action (accent color, prominent styling)
- "Dismiss" button as secondary action (neutral styling)
- Button sizing: minimum 44pt touch target, 80pt minimum width
- Keyboard support: Enter key triggers annotate, Escape triggers dismiss

### Animation and Transitions
- Fade-in animation over 0.3 seconds using SwiftUI withAnimation
- Scale animation from 0.8 to 1.0 during fade-in for polish
- Fade-out animation over 0.2 seconds for quick dismissal
- Smooth position adjustments if window needs repositioning
- Spring animation parameters: duration 0.5s, dampingFraction 0.8

## Approach Options

**Option A: NSPanel + SwiftUI Content** (Selected)
- Pros: Lightweight window, automatic focus management, good for utility windows
- Cons: Limited styling options, may not provide exact control needed

**Option B: NSWindow + Custom Configuration**
- Pros: Full control over window behavior, styling, and level
- Cons: More complex setup, need to handle focus management manually

**Option C: NSPopover Attached to Invisible View**
- Pros: Automatic positioning, built-in arrow styling
- Cons: Not suitable for screen-corner positioning, limited customization

**Rationale:** Option A (NSPanel) provides the best balance of simplicity and functionality. NSPanel is specifically designed for utility windows like this preview, handles focus management appropriately, and integrates well with SwiftUI while providing the floating behavior we need.

## External Dependencies

**No new external dependencies required**
- Uses existing SwiftUI framework for UI components
- Leverages NSScreen APIs already used in capture system
- Integrates with existing AnnotationCaptureManager workflow
- Utilizes current CGImage and rendering infrastructure

**Rationale:** The feature can be implemented entirely with existing system frameworks and project dependencies, maintaining the project's minimal dependency philosophy while ensuring full macOS integration.

## Integration Points

### MenuBarManager Integration
- Modify `handleAreaSelected()` to show preview instead of immediate annotation
- Add new preview lifecycle management methods
- Update existing `showAnnotationInterface()` to be called from preview
- Integrate preview window management with existing window cleanup

### AnnotationCaptureManager Integration
- Add intermediate state between capture completion and annotation start
- Modify capture workflow to support preview-then-annotate pattern
- Maintain existing annotation session management after preview dismissal
- Ensure proper cleanup if capture is dismissed from preview

### CaptureEngine Integration
- No direct changes needed to CaptureEngine
- Preview receives captured CGImage through existing workflow
- Maintains existing image quality and format handling
- Uses current capture error handling and permission system

## Window Management Strategy

### Window Lifecycle
1. **Creation:** Instantiate NSPanel with SwiftUI hosting controller when capture completes
2. **Display:** Position window in bottom-right corner with fade-in animation
3. **Interaction:** Handle button clicks and keyboard events, manage timer state
4. **Dismissal:** Fade-out animation followed by window cleanup and memory deallocation

### Memory Management
- Weak references to prevent retain cycles between preview and parent managers
- Proper cleanup of timer references and animation tasks
- SwiftUI view lifecycle management through hosting controller
- Automatic image memory management using existing CGImage handling

### Focus and Event Handling
- Window accepts first responder for keyboard events
- Non-activating window to avoid disrupting user's current application focus
- Event handling limited to preview-specific actions (buttons, keyboard shortcuts)
- Proper event forwarding for system-level shortcuts and accessibility

## Performance Considerations

### Image Processing
- Reuse captured CGImage without additional processing
- SwiftUI automatic scaling for thumbnail display
- No additional image format conversions required
- Memory efficient thumbnail rendering using native SwiftUI

### Animation Performance
- Use SwiftUI's hardware-accelerated animation system
- Limit animation complexity to maintain 60fps performance
- Efficient timer implementation using SwiftUI's Timer publisher
- Avoid unnecessary redraws during countdown display

### Window Performance
- Lightweight NSPanel creation and management
- Minimal window update cycles during timer countdown
- Efficient cleanup and deallocation when preview closes
- No background processing or continuous updates required
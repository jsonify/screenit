# Product Roadmap

> Last Updated: 2025-01-27
> Version: 1.0.0
> Status: Planning

## Phase 0: Already Completed

The following infrastructure has been established:

- [x] Product Requirements Document - Comprehensive MVP specification with technical architecture
- [x] Project Vision - Open source CleanShot X alternative with clear differentiation strategy
- [x] Technical Architecture - SwiftUI + ScreenCaptureKit + Core Data stack defined

## Phase 1: Core Screenshot Engine ✅ COMPLETED

**Goal:** Establish fundamental screen capture capability with basic UI
**Success Criteria:** User can capture screen areas and save images to disk

### Must-Have Features

- [x] Basic SwiftUI Menu Bar Application - Create menu bar app with status item `L`
- [x] ScreenCaptureKit Integration - Implement basic screen capture functionality `L` 
- [x] Capture Overlay UI - Crosshair cursor with selection rectangle `M`
- [x] Image Save Functionality - Basic save to Desktop workflow `S`
- [x] Global Hotkey Registration - Cmd+Shift+4 triggers capture mode `M`

### Should-Have Features

- [x] Screen Capture Permissions - Handle macOS permission requests gracefully `S`
- [x] Basic Error Handling - User-friendly error messages for common failures `S`

### Dependencies

- ✅ macOS 15+ development environment with Xcode 15+
- ✅ ScreenCaptureKit permission handling

## Phase 2: Professional Capture Tools ✅ COMPLETED

**Goal:** Add professional-grade capture features and visual feedback
**Success Criteria:** Pixel-perfect selection with developer-focused tools

### Must-Have Features

- [x] Magnifier Window - Pixel zoom with RGB color display `M`
- [x] Live Coordinate Display - Real-time pixel position feedback `S`
- [x] Selection Dimensions - Width/height overlay during selection `S`
- [x] Dimmed Background Overlay - Visual feedback for selection area `S`
- [x] Keyboard Controls - Escape to cancel, Enter to confirm `S`

### Should-Have Features

- [x] Color Picker Tool - Click to sample RGB values during selection `M` (Integrated in magnifier)
- [ ] Selection Refinement - Arrow keys for pixel-perfect adjustment `S`

### Dependencies

- ✅ Phase 1 completion
- ✅ Performance optimization for real-time overlay updates

## Phase 3: Annotation System (2-3 weeks)

**Goal:** Professional annotation tools with persistence
**Success Criteria:** Full annotation workflow with undo/redo

### Must-Have Features

- [ ] SwiftUI Canvas Integration - Drawing surface for annotations `M`
- [ ] Arrow Annotation Tool - Configurable color and thickness `M`
- [ ] Text Annotation Tool - Font size and color selection `M`
- [ ] Rectangle Tool - Outline rectangles with style options `S`
- [ ] Highlight/Blur Tool - Area highlighting and privacy blur `M`
- [ ] Annotation Toolbar - Tool selection UI with keyboard shortcuts `S`
- [ ] Undo/Redo System - Complete annotation history management `M`

### Should-Have Features

- [ ] Color Palette - 6 predefined colors with custom color picker `S`
- [ ] Annotation Persistence - Save annotations with image data `M`

### Dependencies

- Phase 2 completion
- SwiftUI Canvas performance testing

## Phase 4: Data Persistence & History (2 weeks)

**Goal:** Capture history with Core Data backend
**Success Criteria:** Persistent storage with thumbnail grid view

### Must-Have Features

- [ ] Core Data Stack - Database setup with CaptureItem and Annotation models `M`
- [ ] History Storage - Save captures with metadata and thumbnails `M`
- [ ] History Grid View - Thumbnail interface for recent captures `M`
- [ ] Copy to Clipboard - Quick clipboard action from history `S`
- [ ] Delete from History - Remove unwanted captures `S`

### Should-Have Features

- [ ] History Metadata - Timestamp, dimensions, file size tracking `S`
- [ ] Export Options - Save As dialog with custom locations `S`
- [ ] History Capacity Management - Configurable retention limits `S`

### Dependencies

- Phase 3 completion
- Core Data migration strategy

## Phase 5: Polish & Preferences (1-2 weeks)

**Goal:** User customization and production-ready polish
**Success Criteria:** Configurable preferences with stable performance

### Must-Have Features

- [ ] Preferences Window - SwiftUI settings interface `M`
- [ ] Hotkey Customization - User-configurable keyboard shortcuts `M`
- [ ] Menu Bar Visibility - Toggle status bar icon display `S`
- [ ] Default Save Location - Custom folder selection `S`
- [ ] History Retention Settings - Configurable capture limit `S`

### Should-Have Features

- [ ] Annotation Defaults - Preset tool colors and thickness `S`
- [ ] Launch at Login - System integration option `S`
- [ ] Performance Optimization - Memory usage and startup time `M`

### Dependencies

- Phase 4 completion
- User testing and feedback integration

## Future Phases (Post-MVP)

### Phase 6: Enhanced Capture (Future)
- Scrolling capture for web pages and long documents
- Window-specific capture modes
- Multi-monitor support optimization
- Timed capture with countdown

### Phase 7: Advanced Features (Future)
- Screen recording with annotation overlay
- OCR text extraction from captures
- Advanced editing tools (crop, resize, filters)
- Export format options (PNG, JPG, PDF, WebP)

### Phase 8: Community & Polish (Future)
- Plugin system for third-party extensions
- Accessibility features and VoiceOver support
- Performance optimizations for large images
- Community contribution guidelines and documentation

## Risk Mitigation

### Technical Risks
- **ScreenCaptureKit Complexity:** Prototype early in Phase 1
- **Global Hotkey Conflicts:** Test with common applications
- **SwiftUI Canvas Performance:** Benchmark annotation rendering
- **Core Data Migrations:** Plan schema evolution strategy

### Timeline Risks
- **macOS Permission Changes:** Monitor OS updates and deprecations
- **Third-Party Conflicts:** Test with popular screenshot apps
- **Performance Bottlenecks:** Regular profiling throughout development
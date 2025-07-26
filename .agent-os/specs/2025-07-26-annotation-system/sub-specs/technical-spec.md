# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-26-annotation-system/spec.md

> Created: 2025-07-26
> Version: 1.0.0

## Technical Requirements

### SwiftUI Canvas Integration
- Canvas view overlaid on captured image with 1:1 pixel mapping
- Real-time drawing updates with 60fps performance target
- Touch/mouse input handling with pressure sensitivity detection
- Canvas state management using @State and @StateObject patterns
- Memory-efficient rendering for large images (up to 4K resolution)

### Annotation Tool System
- Protocol-based tool architecture for extensible annotation types
- Tool state management with current tool selection and configuration
- Interactive drawing modes with start/end point detection for arrows and rectangles
- Text input handling with inline editing and configurable typography
- Effect application system for highlight and blur operations

### Performance Requirements
- Canvas rendering: <16ms per frame (60fps) during active drawing
- Annotation creation: <100ms response time from user input to visual feedback
- Memory usage: <50MB additional overhead for annotation system
- Image export: <2 seconds for 4K images with complex annotations

### User Interface Requirements
- Toolbar with tool icons, color picker, and thickness controls
- Keyboard shortcuts for all tools (A=arrow, T=text, R=rectangle, H=highlight, B=blur)
- Visual feedback for selected tool state and drawing preview
- Color palette with 6 predefined colors plus custom color picker
- Non-intrusive UI that doesn't obstruct the annotation area

## Approach Options

**Option A: Single Canvas with Layer Management**
- Pros: Simple architecture, efficient rendering, easy state management
- Cons: Complex layer ordering, potential performance issues with many annotations

**Option B: Multi-Canvas Overlay System** (Selected)
- Pros: Isolated tool rendering, better performance isolation, cleaner separation of concerns
- Cons: More complex coordinate management, multiple canvas synchronization

**Option C: Core Graphics with SwiftUI Wrapper**
- Pros: Maximum performance, precise control over rendering
- Cons: Complex SwiftUI integration, loss of declarative benefits

**Rationale:** Option B provides the best balance of performance and maintainability. Each annotation type can have its own rendering layer, making it easier to implement undo/redo and manage tool-specific drawing logic while maintaining SwiftUI's declarative approach.

## Architecture Design

### Core Components

**AnnotationEngine**
- Central coordination system managing all annotation functionality
- Tool registry and state management
- Canvas coordination and event routing
- Undo/redo history management

**Tool System**
- `AnnotationTool` protocol defining common tool interface
- `ArrowTool`, `TextTool`, `RectangleTool`, `HighlightTool`, `BlurTool` implementations
- Tool configuration models for color, thickness, and style properties
- Interactive drawing state machines for each tool type

**Canvas System**
- `AnnotationCanvas` main drawing surface with image background
- Tool-specific drawing overlays for real-time preview
- Hit testing and gesture recognition for precise interaction
- Export functionality combining image and annotations

### Data Models

```swift
// Core annotation data structure
struct Annotation: Identifiable, Codable {
    let id: UUID
    let type: AnnotationType
    let properties: AnnotationProperties
    let geometry: AnnotationGeometry
    let timestamp: Date
}

// Tool configuration and state
class AnnotationToolState: ObservableObject {
    @Published var selectedTool: AnnotationType
    @Published var color: Color
    @Published var thickness: Double
    @Published var fontSize: Double
}

// Undo/redo history management
class AnnotationHistory: ObservableObject {
    @Published var annotations: [Annotation]
    private var undoStack: [AnnotationCommand]
    private var redoStack: [AnnotationCommand]
}
```

### Integration Points

**CaptureEngine Integration**
- Seamless transition from capture mode to annotation mode
- Shared image data structure with annotation metadata
- Consistent coordinate system mapping between capture and annotation

**Menu Bar Integration**
- Annotation mode accessible through menu bar actions
- Global shortcuts for entering annotation mode from history
- Quick access to recently used annotation tools

**Future Core Data Integration**
- Annotation persistence model designed for Phase 4 integration
- Metadata structure compatible with capture history storage
- Efficient serialization for annotation data

## External Dependencies

**No External Dependencies Required**
- Implementation uses only SwiftUI, Foundation, and Core Graphics frameworks
- All annotation functionality built with native Apple frameworks
- Maintains project goal of minimal external dependencies

**Justification:** SwiftUI Canvas provides all necessary drawing capabilities for professional annotation tools. Core Graphics integration through Canvas gives us the precision needed for pixel-perfect annotations while maintaining SwiftUI's declarative architecture benefits.
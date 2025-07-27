# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-27-data-persistence-history/spec.md

> Created: 2025-07-27
> Version: 1.0.0

## Technical Requirements

- Core Data stack with NSPersistentContainer for macOS 15+ targeting SQLite store
- CaptureItem entity with relationships to AnnotationData entities for annotation persistence
- Thumbnail generation system using NSImage/UIImage resizing with maximum 200x200 pixel constraints
- SwiftUI LazyVGrid for performance-optimized history display supporting up to 100+ items
- Automatic storage cleanup with configurable retention policies (default 10 items, range 5-50)
- Export functionality supporting PNG format with original quality preservation
- Thread-safe Core Data operations using NSManagedObjectContext.perform patterns

## Approach Options

**Option A: Single Core Data Context**
- Pros: Simpler implementation, fewer synchronization issues, easier debugging
- Cons: UI blocking during heavy operations, less responsive user experience

**Option B: Multiple Context Architecture** (Selected)
- Pros: Background processing, responsive UI, better separation of concerns
- Cons: More complex synchronization, potential for merge conflicts

**Rationale:** Option B provides better user experience and aligns with Apple's recommended Core Data patterns for macOS applications. The background context handles data operations while the main context manages UI updates.

## Core Data Schema Design

### CaptureItem Entity
- `id: UUID` - Primary identifier
- `timestamp: Date` - Capture creation time
- `imageData: Data` - Compressed PNG image data
- `thumbnailData: Data` - Compressed thumbnail image (200x200 max)
- `width: Int32` - Original image width in pixels
- `height: Int32` - Original image height in pixels
- `fileSize: Int64` - Original image size in bytes
- `annotations: Set<AnnotationData>` - One-to-many relationship

### AnnotationData Entity
- `id: UUID` - Primary identifier
- `type: String` - Annotation type (arrow, text, rectangle, highlight, blur)
- `x: Double` - X coordinate position
- `y: Double` - Y coordinate position
- `width: Double` - Annotation width (for rectangles/highlights)
- `height: Double` - Annotation height (for rectangles/highlights)
- `colorData: Data` - Serialized Color information
- `thickness: Double` - Line thickness for drawing tools
- `textContent: String?` - Text content for text annotations
- `fontSize: Double` - Font size for text annotations
- `capture: CaptureItem` - Many-to-one relationship

## SwiftUI Architecture

### DataManager (ObservableObject)
- Manages Core Data stack initialization and configuration
- Provides @Published array of CaptureItem objects for UI binding
- Handles background context operations for save/delete/export operations
- Implements NSFetchedResultsController for automatic UI updates

### HistoryGridView (SwiftUI View)
- LazyVGrid with adaptive columns (minimum 150pt width) for responsive layout
- AsyncImage-style loading for thumbnails with placeholder states
- Context menu integration for copy/delete/export actions per item
- Pull-to-refresh gesture support for manual history updates

### CaptureItemView (SwiftUI View)
- Thumbnail display with metadata overlay (timestamp, dimensions)
- Selection state management for batch operations
- Tap gesture for full-screen preview navigation
- Accessibility support with VoiceOver descriptions

## External Dependencies

**None Required** - All functionality implemented using native frameworks:
- **Core Data:** Built into macOS SDK for persistent storage
- **SwiftUI:** Native UI framework for grid and navigation views
- **Foundation:** Image processing and file operations
- **AppKit:** NSImage operations for thumbnail generation
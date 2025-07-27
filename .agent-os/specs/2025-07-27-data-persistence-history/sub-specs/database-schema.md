# Database Schema

This is the database schema implementation for the spec detailed in @.agent-os/specs/2025-07-27-data-persistence-history/spec.md

> Created: 2025-07-27
> Version: 1.0.0

## Core Data Model Changes

### New Entities

#### CaptureItem Entity
```swift
// Entity: CaptureItem
// Codegen: NSManagedObject Subclass

@NSManaged public var id: UUID
@NSManaged public var timestamp: Date
@NSManaged public var imageData: Data
@NSManaged public var thumbnailData: Data
@NSManaged public var width: Int32
@NSManaged public var height: Int32
@NSManaged public var fileSize: Int64
@NSManaged public var annotations: NSSet?
```

**Attributes:**
- `id` (UUID, Required, Indexed) - Primary identifier with unique constraint
- `timestamp` (Date, Required, Indexed) - Creation timestamp for sorting
- `imageData` (Binary Data, Required) - PNG image data with external storage
- `thumbnailData` (Binary Data, Required) - Compressed thumbnail data
- `width` (Integer 32, Required) - Original image width in pixels
- `height` (Integer 32, Required) - Original image height in pixels
- `fileSize` (Integer 64, Required) - Original image size in bytes

**Relationships:**
- `annotations` (To-Many, AnnotationData.capture, Delete Rule: Cascade, Optional)

#### AnnotationData Entity
```swift
// Entity: AnnotationData
// Codegen: NSManagedObject Subclass

@NSManaged public var id: UUID
@NSManaged public var type: String
@NSManaged public var x: Double
@NSManaged public var y: Double
@NSManaged public var width: Double
@NSManaged public var height: Double
@NSManaged public var colorData: Data
@NSManaged public var thickness: Double
@NSManaged public var textContent: String?
@NSManaged public var fontSize: Double
@NSManaged public var capture: CaptureItem?
```

**Attributes:**
- `id` (UUID, Required, Indexed) - Primary identifier
- `type` (String, Required) - Annotation type: "arrow", "text", "rectangle", "highlight", "blur"
- `x` (Double, Required) - X coordinate position (0.0-1.0 normalized)
- `y` (Double, Required) - Y coordinate position (0.0-1.0 normalized)
- `width` (Double, Required) - Width for rectangle/highlight annotations
- `height` (Double, Required) - Height for rectangle/highlight annotations
- `colorData` (Binary Data, Required) - Serialized SwiftUI Color data
- `thickness` (Double, Required) - Line thickness (1.0-10.0 range)
- `textContent` (String, Optional) - Text content for text annotations
- `fontSize` (Double, Required) - Font size for text (8.0-72.0 range)

**Relationships:**
- `capture` (To-One, CaptureItem.annotations, Delete Rule: Nullify, Optional)

## Migration Strategy

### Initial Migration (Version 1)
Since this is the first Core Data implementation, no migration is required. The model will be created with initial schema version 1.

### Core Data Stack Configuration
```swift
// NSPersistentContainer configuration
container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
                                                       forKey: NSPersistentHistoryTrackingKey)
container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
                                                       forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

// Enable external binary data storage for images
container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
                                                       forKey: NSBinaryDataExternalRecordFileStorageKey)
```

## Performance Optimizations

### Indexes
- `CaptureItem.id` - Primary key index (automatic)
- `CaptureItem.timestamp` - Sorting and filtering index
- `AnnotationData.id` - Primary key index (automatic)
- `AnnotationData.capture` - Foreign key index (automatic)

### Fetch Request Optimizations
```swift
// Optimized fetch for history grid view
let request: NSFetchRequest<CaptureItem> = CaptureItem.fetchRequest()
request.sortDescriptors = [NSSortDescriptor(keyPath: \CaptureItem.timestamp, ascending: false)]
request.fetchLimit = 50  // Pagination support
request.propertiesToFetch = ["id", "timestamp", "thumbnailData", "width", "height"]
request.relationshipKeyPathsForPrefetching = ["annotations"]
```

### Storage Considerations
- External binary data storage for `imageData` and `thumbnailData` to prevent database bloat
- Automatic SQLite WAL mode for better concurrent access performance
- Background context for all write operations to prevent UI blocking

## Data Validation Rules

### CaptureItem Validation
- `width` and `height` must be positive integers (> 0)
- `fileSize` must be positive (> 0)
- `imageData` and `thumbnailData` must be valid PNG data
- `timestamp` cannot be in the future

### AnnotationData Validation
- `type` must be one of: "arrow", "text", "rectangle", "highlight", "blur"
- `x`, `y`, `width`, `height` must be in range 0.0-1.0 (normalized coordinates)
- `thickness` must be in range 1.0-10.0
- `fontSize` must be in range 8.0-72.0
- `textContent` required when `type` is "text", null otherwise
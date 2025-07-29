# Database Schema

This is the database schema implementation for the spec detailed in @.agent-os/specs/2025-07-29-preferences-window/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Schema Changes

### New Core Data Entity: UserPreferences

```swift
// UserPreferences Entity
entity UserPreferences {
    // General Settings
    var defaultSaveLocation: String? // Bookmark data for selected folder
    var historyRetentionLimit: Int32 = 10 // Number of captures to retain
    var showMenuBarIcon: Bool = true // Menu bar visibility toggle
    var launchAtLogin: Bool = false // Login item registration
    
    // Hotkey Settings
    var captureHotkey: String? // JSON string for hotkey combination
    var annotationHotkey: String? // JSON string for annotation mode hotkey
    var historyHotkey: String? // JSON string for history window hotkey
    
    // Annotation Defaults
    var defaultArrowColor: String = "#FF0000" // Hex color string
    var defaultTextColor: String = "#000000" // Hex color string  
    var defaultRectangleColor: String = "#0066CC" // Hex color string
    var defaultHighlightColor: String = "#FFFF00" // Hex color string
    var defaultArrowThickness: Float = 2.0 // Line thickness
    var defaultTextSize: Float = 14.0 // Font size
    var defaultRectangleThickness: Float = 2.0 // Border thickness
    
    // Advanced Settings
    var autoSaveToDesktop: Bool = true // Quick save behavior
    var showCaptureNotifications: Bool = true // System notifications
    var enableSoundEffects: Bool = false // Audio feedback
    
    // Metadata
    var createdAt: Date = Date() // Creation timestamp
    var updatedAt: Date = Date() // Last modification timestamp
}
```

### Core Data Migration

```swift
// Migration from existing Core Data stack
// Add UserPreferences entity to existing model version
// Create new model version with UserPreferences entity
// Implement lightweight migration for existing CaptureItem data

// NSManagedObjectModel migration mapping
let mapping = NSEntityMapping()
mapping.name = "UserPreferencesToUserPreferences"
mapping.mappingType = .addEntityMappingType
mapping.sourceEntityName = nil
mapping.destinationEntityName = "UserPreferences"
```

### Indexes and Constraints

```swift
// Core Data Model Configuration
// Primary key: Auto-generated NSManagedObjectID
// Constraints: Single instance (singleton pattern)
// Indexes: None required (single entity instance)
// Relationships: None (standalone preferences entity)

// Validation Rules
var historyRetentionLimit: Int32 {
    willSet {
        guard newValue >= 1 && newValue <= 1000 else {
            // Reset to default if invalid
            return
        }
    }
}
```

### Data Access Patterns

```swift
// Singleton Pattern Implementation
class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()
    
    @Published var preferences: UserPreferences
    
    private init() {
        // Fetch or create single preferences instance
        let request: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let existing = results.first {
                preferences = existing
            } else {
                preferences = UserPreferences(context: context)
                try context.save()
            }
        } catch {
            // Create default preferences on error
            preferences = UserPreferences(context: context)
        }
    }
}
```

## Rationale

### Single Entity Design
The UserPreferences entity follows a singleton pattern to store all application settings in one location. This approach simplifies data access and ensures consistency across the application.

### String Storage for Complex Data
Hotkey combinations and color values are stored as strings (JSON/Hex) to maintain flexibility and avoid complex Core Data relationships while keeping the schema simple.

### Timestamp Tracking
CreatedAt and updatedAt timestamps enable preferences versioning and troubleshooting capabilities for future development needs.

### Default Values
All preference properties include sensible defaults that match the current application behavior, ensuring smooth migration and first-run experience.
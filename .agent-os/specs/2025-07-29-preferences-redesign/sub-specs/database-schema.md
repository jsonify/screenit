# Database Schema

This is the database schema implementation for the spec detailed in @.agent-os/specs/2025-07-29-preferences-redesign/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Changes Required

### New Properties for UserPreferences Entity

**Screenshots Panel Settings:**
- `fileFormat: String` - PNG/JPEG selection (default: "PNG")
- `retinaScaling: Bool` - Scale Retina screenshots to 1x (default: false)  
- `colorManagement: Bool` - Convert to sRGB profile (default: false)
- `addFrameBorder: Bool` - Add 1px border to all screenshots (default: false)
- `backgroundPreset: String` - Background tool preset (default: "None")
- `selfTimerInterval: Int32` - Self-timer interval in seconds (default: 5)
- `showCursorInScreenshots: Bool` - Show cursor on screenshots (default: false)
- `freezeScreenDuringCapture: Bool` - Freeze screen when taking screenshot (default: false)
- `crosshairMode: String` - Crosshair mode setting (default: "Disabled")
- `showMagnifier: Bool` - Show magnifier during capture (default: true)

**Quick Access Panel Settings:**
- `overlayPosition: String` - Position on screen (default: "Left")
- `moveToActiveScreen: Bool` - Move to active screen for multi-display (default: true)
- `overlaySize: Float` - Overlay size setting (default: 1.0)
- `autoCloseEnabled: Bool` - Enable auto-close functionality (default: false)
- `autoCloseAction: String` - Auto-close action (default: "Save and Close")
- `autoCloseInterval: Int32` - Auto-close interval in seconds (default: 30)
- `closeAfterDragging: Bool` - Close after dragging (default: true)
- `closeAfterCloudUpload: Bool` - Close after uploading (default: true)
- `saveButtonBehavior: String` - Save button behavior (default: "Save to Export location")

**Advanced Panel Settings:**
- `fileNamingPattern: String` - File naming pattern (default: "Edit")
- `askForNameAfterCapture: Bool` - Ask for name after every capture (default: false)
- `addRetinaFileSuffix: Bool` - Add "@2x" suffix to Retina screenshots (default: true)
- `clipboardCopyMode: String` - Copy to clipboard mode (default: "File & Image (default)")
- `pinnedScreenshotRoundedCorners: Bool` - Rounded corners for pinned screenshots (default: true)
- `pinnedScreenshotShadow: Bool` - Shadow for pinned screenshots (default: true)
- `pinnedScreenshotBorder: Bool` - Border for pinned screenshots (default: true)
- `historyRetentionPeriod: String` - Keep history period (default: "1 week")
- `allInOneRememberLastSelection: Bool` - Remember last selection (default: true)
- `textRecognitionLanguage: String` - Text recognition language (default: "Automatically Detect Language")
- `textRecognitionKeepLineBreaks: Bool` - Keep line breaks (default: false)
- `textRecognitionDetectLinks: Bool` - Detect links (default: true)
- `allowApiControl: Bool` - Allow applications to control CleanShot (default: false)

## Migration Strategy

**Core Data Migration Steps:**
1. Create new model version with additional properties
2. Configure all new properties as optional with default values
3. Implement lightweight migration for automatic handling
4. Update UserPreferences.createWithDefaults() method to set new defaults
5. Add validation and getter/setter methods for new properties

**Default Values Implementation:**
```swift
// In UserPreferences+CoreDataClass.swift
static func createWithDefaults(in context: NSManagedObjectContext) -> UserPreferences {
    let preferences = UserPreferences(context: context)
    
    // Existing defaults...
    
    // New Screenshots defaults
    preferences.fileFormat = "PNG"
    preferences.retinaScaling = false
    preferences.colorManagement = false
    preferences.addFrameBorder = false
    preferences.backgroundPreset = "None"
    preferences.selfTimerInterval = 5
    preferences.showCursorInScreenshots = false
    preferences.freezeScreenDuringCapture = false
    preferences.crosshairMode = "Disabled"
    preferences.showMagnifier = true
    
    // New Quick Access defaults
    preferences.overlayPosition = "Left"
    preferences.moveToActiveScreen = true
    preferences.overlaySize = 1.0
    preferences.autoCloseEnabled = false
    preferences.autoCloseAction = "Save and Close"
    preferences.autoCloseInterval = 30
    preferences.closeAfterDragging = true
    preferences.closeAfterCloudUpload = true
    preferences.saveButtonBehavior = "Save to Export location"
    
    // New Advanced defaults
    preferences.fileNamingPattern = "Edit"
    preferences.askForNameAfterCapture = false
    preferences.addRetinaFileSuffix = true
    preferences.clipboardCopyMode = "File & Image (default)"
    preferences.pinnedScreenshotRoundedCorners = true
    preferences.pinnedScreenshotShadow = true
    preferences.pinnedScreenshotBorder = true
    preferences.historyRetentionPeriod = "1 week"
    preferences.allInOneRememberLastSelection = true
    preferences.textRecognitionLanguage = "Automatically Detect Language"
    preferences.textRecognitionKeepLineBreaks = false
    preferences.textRecognitionDetectLinks = true
    preferences.allowApiControl = false
    
    return preferences
}
```

## Rationale

**Schema Design Decisions:**
- All new properties are optional to ensure backward compatibility
- String-based enums used for dropdown selections to match UI exactly
- Boolean flags for simple toggle preferences
- Numeric types (Int32, Float) for quantitative settings
- Default values chosen to match current application behavior where applicable

**Migration Safety:**
- Lightweight migration used for automatic handling during app updates
- No data transformation required, only new columns added
- Existing user preferences preserved without modification
- Fallback defaults ensure app continues working if migration encounters issues
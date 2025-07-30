import Foundation
import CoreData

@objc(UserPreferences)
public class UserPreferences: NSManagedObject {
    
    // MARK: - Convenience Initializer
    
    /// Creates a new UserPreferences entity with default values
    /// - Parameter context: The managed object context
    /// - Returns: A new UserPreferences instance with default values set
    public static func createWithDefaults(in context: NSManagedObjectContext) -> UserPreferences {
        let preferences = UserPreferences(context: context)
        
        // Set default values as specified in the database schema
        preferences.historyRetentionLimit = 10
        preferences.showMenuBarIcon = true
        preferences.launchAtLogin = false
        preferences.autoSaveToDesktop = true
        preferences.showCaptureNotifications = true
        preferences.enableSoundEffects = false
        preferences.enableSounds = false
        preferences.customSaveLocation = ""
        preferences.saveLocation = "desktop"
        preferences.showAnnotationToolbar = true
        preferences.autoSaveToHistory = true
        preferences.enableHighDPICapture = true
        preferences.enableNotifications = true
        preferences.showPreviewWindow = true
        preferences.defaultAnnotationColor = "#FF0000"
        preferences.enableHistoryThumbnails = true
        preferences.previewDuration = 6.0
        preferences.compressionQuality = 0.8
        preferences.maxImageSize = 8192
        
        // Annotation defaults
        preferences.defaultArrowColor = "#FF0000"
        preferences.defaultTextColor = "#000000"
        preferences.defaultRectangleColor = "#0066CC"
        preferences.defaultHighlightColor = "#FFFF00"
        preferences.defaultArrowThickness = 2.0
        preferences.defaultTextSize = 14.0
        preferences.defaultRectangleThickness = 2.0
        
        // General preferences defaults (from preferences_general.png mock)
        preferences.showQuickAccessOverlayAfterCapture = true
        preferences.copyFileToClipboardAfterCapture = false
        preferences.saveAfterCapture = true
        preferences.uploadToCloudAfterCapture = false
        preferences.openAnnotateToolAfterCapture = false
        preferences.pinToScreenAfterCapture = false
        preferences.openVideoEditorAfterCapture = false
        preferences.playSounds = false
        preferences.shutterSound = "Default"
        preferences.hideDesktopIconsWhileCapturing = false
        
        // Screenshots preferences defaults (from preferences_screenshots.png mock)
        preferences.fileFormat = "PNG"
        preferences.scaleRetinaScreenshotsTo1x = false
        preferences.convertToSRGBProfile = false
        preferences.add1pxBorderToScreenshots = false
        preferences.backgroundPreset = "None"
        preferences.selfTimerInterval = 5
        preferences.showCursorInScreenshots = false
        preferences.freezeScreenWhenTakingScreenshot = false
        preferences.crosshairMode = "Disabled"
        preferences.showMagnifierInCrosshair = true
        
        // Annotate preferences defaults (from preferences_annotate.png mock)
        preferences.inverseArrowDirection = false
        preferences.smoothDrawing = true
        preferences.rememberBackgroundToolState = false
        preferences.drawShadowOnObjects = true
        preferences.automaticallyExpandCanvas = false
        preferences.showColorNames = false
        preferences.alwaysOnTop = false
        preferences.showDockIcon = true
        
        // Quick Access preferences defaults (from preferences_quick-access.png mock)
        preferences.overlayPositionOnScreen = "Left"
        preferences.moveToActiveScreen = true
        preferences.overlaySize = 1.0
        preferences.enableAutoClose = false
        preferences.autoCloseAction = "Save and Close"
        preferences.autoCloseInterval = 30
        preferences.closeAfterDragging = true
        preferences.closeAfterCloudUpload = true
        preferences.saveButtonBehavior = "Save to \"Export location\""
        
        // Advanced preferences defaults (from preferences_advanced.png mock)
        preferences.fileNamingPattern = "Edit"
        preferences.askForNameAfterEveryCapture = false
        preferences.addRetinaSuffixToFilenames = true
        preferences.clipboardCopyMode = "File & Image (default)"
        preferences.pinnedScreenshotRoundedCorners = true
        preferences.pinnedScreenshotShadow = true
        preferences.pinnedScreenshotBorder = true
        preferences.historyRetentionPeriod = "1 week"
        preferences.rememberLastAllInOneSelection = true
        preferences.textRecognitionLanguage = "Automatically Detect Language"
        preferences.textRecognitionKeepLineBreaks = false
        preferences.textRecognitionDetectLinks = true
        preferences.allowApplicationsToControlApp = false
        
        // Set timestamps
        let now = Date()
        preferences.createdAt = now
        preferences.updatedAt = now
        
        return preferences
    }
    
    // MARK: - Validation
    
    /// Validates the history retention limit value
    /// - Returns: True if the value is within valid range (1-1000)
    public var isHistoryRetentionLimitValid: Bool {
        return historyRetentionLimit >= 1 && historyRetentionLimit <= 1000
    }
    
    /// Validates a hex color string format
    /// - Parameter colorHex: The hex color string to validate
    /// - Returns: True if the color is a valid hex format
    public static func isValidHexColor(_ colorHex: String?) -> Bool {
        guard let color = colorHex else { return false }
        let hexPattern = "^#[0-9A-Fa-f]{6}$"
        return color.range(of: hexPattern, options: .regularExpression) != nil
    }
    
    /// Validates all color properties
    /// - Returns: True if all color hex values are valid
    public var areColorsValid: Bool {
        return UserPreferences.isValidHexColor(defaultArrowColor) &&
               UserPreferences.isValidHexColor(defaultTextColor) &&
               UserPreferences.isValidHexColor(defaultRectangleColor) &&
               UserPreferences.isValidHexColor(defaultHighlightColor)
    }
    
    // MARK: - New Properties Validation
    
    /// Validates the file format selection
    /// - Returns: True if the file format is supported
    public var isFileFormatValid: Bool {
        let validFormats = ["PNG", "JPEG", "HEIF", "TIFF"]
        return validFormats.contains(fileFormat)
    }
    
    /// Validates the self-timer interval
    /// - Returns: True if the interval is within valid range (1-300 seconds)
    public var isSelfTimerIntervalValid: Bool {
        return selfTimerInterval >= 1 && selfTimerInterval <= 300
    }
    
    /// Validates the overlay size
    /// - Returns: True if the overlay size is within valid range (0.1-3.0)
    public var isOverlaySizeValid: Bool {
        return overlaySize >= 0.1 && overlaySize <= 3.0
    }
    
    /// Validates the auto-close interval
    /// - Returns: True if the interval is within valid range (5-300 seconds)
    public var isAutoCloseIntervalValid: Bool {
        return autoCloseInterval >= 5 && autoCloseInterval <= 300
    }
    
    /// Validates the overlay position setting
    /// - Returns: True if the position is valid
    public var isOverlayPositionValid: Bool {
        let validPositions = ["Left", "Right", "Top", "Bottom", "Center"]
        return validPositions.contains(overlayPositionOnScreen)
    }
    
    /// Validates the crosshair mode setting
    /// - Returns: True if the mode is valid
    public var isCrosshairModeValid: Bool {
        let validModes = ["Disabled", "Enabled", "Always On"]
        return validModes.contains(crosshairMode)
    }
    
    /// Validates the history retention period setting
    /// - Returns: True if the period is valid
    public var isHistoryRetentionPeriodValid: Bool {
        let validPeriods = ["Never", "1 day", "3 days", "1 week", "1 month"]
        return validPeriods.contains(historyRetentionPeriod)
    }
    
    /// Validates the background preset setting
    /// - Returns: True if the preset is valid
    public var isBackgroundPresetValid: Bool {
        let validPresets = ["None", "Blur", "Shadow", "Frame"]
        return validPresets.contains(backgroundPreset)
    }
    
    /// Validates all new properties
    /// - Returns: True if all new properties have valid values
    public var areNewPropertiesValid: Bool {
        return isFileFormatValid &&
               isSelfTimerIntervalValid &&
               isOverlaySizeValid &&
               isAutoCloseIntervalValid &&
               isOverlayPositionValid &&
               isCrosshairModeValid &&
               isHistoryRetentionPeriodValid &&
               isBackgroundPresetValid
    }
    
    // MARK: - Convenience Properties
    
    /// Returns the effective history retention limit, clamped to valid range
    public var effectiveHistoryRetentionLimit: Int32 {
        return max(1, min(1000, historyRetentionLimit))
    }
    
    /// Updates the updatedAt timestamp to current date
    public func updateTimestamp() {
        updatedAt = Date()
    }
    
    // MARK: - Hotkey Parsing
    
    /// Parses the capture hotkey JSON string
    /// - Returns: Dictionary containing hotkey data, or nil if invalid
    public var captureHotkeyData: [String: Any]? {
        guard let hotkeyString = captureHotkey,
              let data = hotkeyString.data(using: .utf8) else { return nil }
        
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    /// Parses the annotation hotkey JSON string
    /// - Returns: Dictionary containing hotkey data, or nil if invalid
    public var annotationHotkeyData: [String: Any]? {
        guard let hotkeyString = annotationHotkey,
              let data = hotkeyString.data(using: .utf8) else { return nil }
        
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    /// Parses the history hotkey JSON string
    /// - Returns: Dictionary containing hotkey data, or nil if invalid
    public var historyHotkeyData: [String: Any]? {
        guard let hotkeyString = historyHotkey,
              let data = hotkeyString.data(using: .utf8) else { return nil }
        
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
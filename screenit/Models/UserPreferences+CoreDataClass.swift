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
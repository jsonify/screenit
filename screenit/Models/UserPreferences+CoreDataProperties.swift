import Foundation
import CoreData

extension UserPreferences {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserPreferences> {
        return NSFetchRequest<UserPreferences>(entityName: "UserPreferences")
    }

    // MARK: - General Settings
    
    @NSManaged public var defaultSaveLocation: String?
    @NSManaged public var historyRetentionLimit: Int32
    @NSManaged public var showMenuBarIcon: Bool
    @NSManaged public var launchAtLogin: Bool
    
    // MARK: - Hotkey Settings
    
    @NSManaged public var captureHotkey: String?
    @NSManaged public var annotationHotkey: String?
    @NSManaged public var historyHotkey: String?
    
    // MARK: - Annotation Defaults
    
    @NSManaged public var defaultArrowColor: String?
    @NSManaged public var defaultTextColor: String?
    @NSManaged public var defaultRectangleColor: String?
    @NSManaged public var defaultHighlightColor: String?
    @NSManaged public var defaultArrowThickness: Float
    @NSManaged public var defaultTextSize: Float
    @NSManaged public var defaultRectangleThickness: Float
    
    // MARK: - Advanced Settings
    
    @NSManaged public var autoSaveToDesktop: Bool
    @NSManaged public var showCaptureNotifications: Bool
    @NSManaged public var enableSoundEffects: Bool
    @NSManaged public var enableSounds: Bool
    @NSManaged public var customSaveLocation: String
    @NSManaged public var saveLocation: String
    @NSManaged public var showAnnotationToolbar: Bool
    @NSManaged public var autoSaveToHistory: Bool
    @NSManaged public var enableHighDPICapture: Bool
    @NSManaged public var enableNotifications: Bool
    @NSManaged public var showPreviewWindow: Bool
    @NSManaged public var defaultAnnotationColor: String
    @NSManaged public var enableHistoryThumbnails: Bool
    @NSManaged public var previewDuration: Double
    @NSManaged public var compressionQuality: Double
    @NSManaged public var maxImageSize: Int32
    
    // MARK: - Metadata
    
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}
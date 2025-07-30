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
    
    // MARK: - General Preferences (from preferences_general.png mock)
    
    @NSManaged public var showQuickAccessOverlayAfterCapture: Bool
    @NSManaged public var copyFileToClipboardAfterCapture: Bool
    @NSManaged public var saveAfterCapture: Bool
    @NSManaged public var uploadToCloudAfterCapture: Bool
    @NSManaged public var openAnnotateToolAfterCapture: Bool
    @NSManaged public var pinToScreenAfterCapture: Bool
    @NSManaged public var openVideoEditorAfterCapture: Bool
    @NSManaged public var playSounds: Bool
    @NSManaged public var shutterSound: String
    @NSManaged public var hideDesktopIconsWhileCapturing: Bool
    
    // MARK: - Screenshots Preferences (from preferences_screenshots.png mock)
    
    @NSManaged public var fileFormat: String
    @NSManaged public var scaleRetinaScreenshotsTo1x: Bool
    @NSManaged public var convertToSRGBProfile: Bool
    @NSManaged public var add1pxBorderToScreenshots: Bool
    @NSManaged public var backgroundPreset: String
    @NSManaged public var selfTimerInterval: Int32
    @NSManaged public var showCursorInScreenshots: Bool
    @NSManaged public var freezeScreenWhenTakingScreenshot: Bool
    @NSManaged public var crosshairMode: String
    @NSManaged public var showMagnifierInCrosshair: Bool
    
    // MARK: - Annotate Preferences (from preferences_annotate.png mock)
    
    @NSManaged public var inverseArrowDirection: Bool
    @NSManaged public var smoothDrawing: Bool
    @NSManaged public var rememberBackgroundToolState: Bool
    @NSManaged public var drawShadowOnObjects: Bool
    @NSManaged public var automaticallyExpandCanvas: Bool
    @NSManaged public var showColorNames: Bool
    @NSManaged public var alwaysOnTop: Bool
    @NSManaged public var showDockIcon: Bool
    
    // MARK: - Quick Access Preferences (from preferences_quick-access.png mock)
    
    @NSManaged public var overlayPositionOnScreen: String
    @NSManaged public var moveToActiveScreen: Bool
    @NSManaged public var overlaySize: Float
    @NSManaged public var enableAutoClose: Bool
    @NSManaged public var autoCloseAction: String
    @NSManaged public var autoCloseInterval: Int32
    @NSManaged public var closeAfterDragging: Bool
    @NSManaged public var closeAfterCloudUpload: Bool
    @NSManaged public var saveButtonBehavior: String
    
    // MARK: - Advanced Preferences (from preferences_advanced.png mock)
    
    @NSManaged public var fileNamingPattern: String
    @NSManaged public var askForNameAfterEveryCapture: Bool
    @NSManaged public var addRetinaSuffixToFilenames: Bool
    @NSManaged public var clipboardCopyMode: String
    @NSManaged public var pinnedScreenshotRoundedCorners: Bool
    @NSManaged public var pinnedScreenshotShadow: Bool
    @NSManaged public var pinnedScreenshotBorder: Bool
    @NSManaged public var historyRetentionPeriod: String
    @NSManaged public var rememberLastAllInOneSelection: Bool
    @NSManaged public var textRecognitionLanguage: String
    @NSManaged public var textRecognitionKeepLineBreaks: Bool
    @NSManaged public var textRecognitionDetectLinks: Bool
    @NSManaged public var allowApplicationsToControlApp: Bool

}
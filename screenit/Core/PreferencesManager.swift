import Foundation
import SwiftUI
import Combine
import CoreData
import OSLog

// MARK: - Preferences Manager

@MainActor
class PreferencesManager: ObservableObject {
    
    // MARK: - Notifications
    
    static let preferencesDidChangeNotification = NSNotification.Name("PreferencesDidChange")
    
    // MARK: - Singleton
    
    static let shared = PreferencesManager()
    
    // MARK: - Published Properties
    
    @Published var preferences: UserPreferences
    @Published var isPreferencesWindowOpen = false
    
    // MARK: - Private Properties
    
    private let persistenceManager: PersistenceManager
    private var preferencesWindow: NSWindow?
    private let logger = Logger(subsystem: "com.screenit.app", category: "PreferencesManager")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        self.persistenceManager = PersistenceManager.shared
        
        logger.info("Initializing PreferencesManager...")
        
        // Load or create preferences
        let context = persistenceManager.viewContext
        let fetchRequest: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let existing = results.first {
                self.preferences = existing
                logger.info("✅ Loaded existing preferences from Core Data - Object ID: \(existing.objectID)")
            } else {
                // Create new preferences with defaults
                self.preferences = UserPreferences.createWithDefaults(in: context)
                try context.save()
                logger.info("✅ Created new preferences with default values - Object ID: \(self.preferences.objectID)")
            }
        } catch {
            logger.error("❌ Failed to load preferences: \(error.localizedDescription)")
            // Fallback: create new preferences
            self.preferences = UserPreferences.createWithDefaults(in: context)
            logger.warning("⚠️ Using fallback preferences object - Object ID: \(self.preferences.objectID)")
        }
        
        // Validate the preferences object
        logger.info("Preferences object status - isDeleted: \(self.preferences.isDeleted), hasContext: \(self.preferences.managedObjectContext != nil)")
        
        // Set up auto-save observation
        setupAutoSave()
    }
    
    /// Internal initializer for testing with custom persistence manager
    internal init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
        
        // Load or create preferences
        let context = persistenceManager.viewContext
        let fetchRequest: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let existing = results.first {
                self.preferences = existing
            } else {
                // Create new preferences with defaults
                self.preferences = UserPreferences.createWithDefaults(in: context)
                try context.save()
            }
        } catch {
            // Fallback: create new preferences
            self.preferences = UserPreferences.createWithDefaults(in: context)
        }
        
        // Set up auto-save observation
        setupAutoSave()
    }
    
    private func setupAutoSave() {
        // Observe changes and auto-save with debouncing
        $preferences
            .dropFirst() // Skip initial load
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] updatedPreferences in
                guard let self = self else { return }
                
                // Validate the preferences object is still valid
                guard !updatedPreferences.isDeleted,
                      let context = updatedPreferences.managedObjectContext,
                      !context.hasChanges || context == self.persistenceManager.viewContext else {
                    self.logger.warning("Preferences object is invalid or from wrong context, skipping save")
                    return
                }
                
                self.savePreferences()
                
                // Update timestamp
                updatedPreferences.updateTimestamp()
                
                // Notify about preference changes
                NotificationCenter.default.post(
                    name: PreferencesManager.preferencesDidChangeNotification,
                    object: updatedPreferences
                )
                
                // Notify about hotkey changes if applicable
                if let hotkeyData = updatedPreferences.captureHotkeyData {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("HotkeyPreferenceChanged"),
                        object: hotkeyData
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Persistence
    
    func savePreferences() {
        guard !preferences.isDeleted,
              let context = preferences.managedObjectContext else {
            logger.error("Cannot save preferences: object is deleted or has no context")
            return
        }
        
        guard context == persistenceManager.viewContext else {
            logger.error("Cannot save preferences: object is not in the correct context")
            return
        }
        
        logger.debug("Saving preferences to Core Data")
        
        do {
            preferences.updateTimestamp()
            try persistenceManager.saveViewContext()
            logger.debug("Preferences saved successfully")
        } catch {
            logger.error("Failed to save preferences: \(error.localizedDescription)")
            
            // Log additional context for debugging
            if let nsError = error as NSError? {
                logger.error("Core Data error details: \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Public Interface
    
    func resetToDefaults() {
        logger.info("Resetting preferences to defaults")
        
        // Update the existing preferences object with defaults
        let context = persistenceManager.viewContext
        let newPreferences = UserPreferences.createWithDefaults(in: context)
        
        // Copy default values to current preferences
        preferences.historyRetentionLimit = newPreferences.historyRetentionLimit
        preferences.showMenuBarIcon = newPreferences.showMenuBarIcon
        preferences.launchAtLogin = newPreferences.launchAtLogin
        preferences.autoSaveToDesktop = newPreferences.autoSaveToDesktop
        preferences.showCaptureNotifications = newPreferences.showCaptureNotifications
        preferences.enableSoundEffects = newPreferences.enableSoundEffects
        preferences.enableSounds = newPreferences.enableSounds
        preferences.customSaveLocation = newPreferences.customSaveLocation
        preferences.saveLocation = newPreferences.saveLocation
        preferences.showAnnotationToolbar = newPreferences.showAnnotationToolbar
        preferences.autoSaveToHistory = newPreferences.autoSaveToHistory
        preferences.enableHighDPICapture = newPreferences.enableHighDPICapture
        preferences.enableNotifications = newPreferences.enableNotifications
        preferences.showPreviewWindow = newPreferences.showPreviewWindow
        preferences.defaultAnnotationColor = newPreferences.defaultAnnotationColor
        preferences.enableHistoryThumbnails = newPreferences.enableHistoryThumbnails
        preferences.previewDuration = newPreferences.previewDuration
        preferences.compressionQuality = newPreferences.compressionQuality
        preferences.maxImageSize = newPreferences.maxImageSize
        
        // Reset annotation defaults
        preferences.defaultArrowColor = newPreferences.defaultArrowColor
        preferences.defaultTextColor = newPreferences.defaultTextColor
        preferences.defaultRectangleColor = newPreferences.defaultRectangleColor
        preferences.defaultHighlightColor = newPreferences.defaultHighlightColor
        preferences.defaultArrowThickness = newPreferences.defaultArrowThickness
        preferences.defaultTextSize = newPreferences.defaultTextSize
        preferences.defaultRectangleThickness = newPreferences.defaultRectangleThickness
        
        // Reset new properties to defaults (from mocks)
        preferences.showQuickAccessOverlayAfterCapture = newPreferences.showQuickAccessOverlayAfterCapture
        preferences.copyFileToClipboardAfterCapture = newPreferences.copyFileToClipboardAfterCapture
        preferences.saveAfterCapture = newPreferences.saveAfterCapture
        preferences.uploadToCloudAfterCapture = newPreferences.uploadToCloudAfterCapture
        preferences.openAnnotateToolAfterCapture = newPreferences.openAnnotateToolAfterCapture
        preferences.pinToScreenAfterCapture = newPreferences.pinToScreenAfterCapture
        preferences.openVideoEditorAfterCapture = newPreferences.openVideoEditorAfterCapture
        preferences.playSounds = newPreferences.playSounds
        preferences.shutterSound = newPreferences.shutterSound
        preferences.hideDesktopIconsWhileCapturing = newPreferences.hideDesktopIconsWhileCapturing
        
        preferences.fileFormat = newPreferences.fileFormat
        preferences.scaleRetinaScreenshotsTo1x = newPreferences.scaleRetinaScreenshotsTo1x
        preferences.convertToSRGBProfile = newPreferences.convertToSRGBProfile
        preferences.add1pxBorderToScreenshots = newPreferences.add1pxBorderToScreenshots
        preferences.backgroundPreset = newPreferences.backgroundPreset
        preferences.selfTimerInterval = newPreferences.selfTimerInterval
        preferences.showCursorInScreenshots = newPreferences.showCursorInScreenshots
        preferences.freezeScreenWhenTakingScreenshot = newPreferences.freezeScreenWhenTakingScreenshot
        preferences.crosshairMode = newPreferences.crosshairMode
        preferences.showMagnifierInCrosshair = newPreferences.showMagnifierInCrosshair
        
        preferences.inverseArrowDirection = newPreferences.inverseArrowDirection
        preferences.smoothDrawing = newPreferences.smoothDrawing
        preferences.rememberBackgroundToolState = newPreferences.rememberBackgroundToolState
        preferences.drawShadowOnObjects = newPreferences.drawShadowOnObjects
        preferences.automaticallyExpandCanvas = newPreferences.automaticallyExpandCanvas
        preferences.showColorNames = newPreferences.showColorNames
        preferences.alwaysOnTop = newPreferences.alwaysOnTop
        preferences.showDockIcon = newPreferences.showDockIcon
        
        preferences.overlayPositionOnScreen = newPreferences.overlayPositionOnScreen
        preferences.moveToActiveScreen = newPreferences.moveToActiveScreen
        preferences.overlaySize = newPreferences.overlaySize
        preferences.enableAutoClose = newPreferences.enableAutoClose
        preferences.autoCloseAction = newPreferences.autoCloseAction
        preferences.autoCloseInterval = newPreferences.autoCloseInterval
        preferences.closeAfterDragging = newPreferences.closeAfterDragging
        preferences.closeAfterCloudUpload = newPreferences.closeAfterCloudUpload
        preferences.saveButtonBehavior = newPreferences.saveButtonBehavior
        
        preferences.fileNamingPattern = newPreferences.fileNamingPattern
        preferences.askForNameAfterEveryCapture = newPreferences.askForNameAfterEveryCapture
        preferences.addRetinaSuffixToFilenames = newPreferences.addRetinaSuffixToFilenames
        preferences.clipboardCopyMode = newPreferences.clipboardCopyMode
        preferences.pinnedScreenshotRoundedCorners = newPreferences.pinnedScreenshotRoundedCorners
        preferences.pinnedScreenshotShadow = newPreferences.pinnedScreenshotShadow
        preferences.pinnedScreenshotBorder = newPreferences.pinnedScreenshotBorder
        preferences.historyRetentionPeriod = newPreferences.historyRetentionPeriod
        preferences.rememberLastAllInOneSelection = newPreferences.rememberLastAllInOneSelection
        preferences.textRecognitionLanguage = newPreferences.textRecognitionLanguage
        preferences.textRecognitionKeepLineBreaks = newPreferences.textRecognitionKeepLineBreaks
        preferences.textRecognitionDetectLinks = newPreferences.textRecognitionDetectLinks
        preferences.allowApplicationsToControlApp = newPreferences.allowApplicationsToControlApp
        
        // Clear hotkeys and save location
        preferences.captureHotkey = nil
        preferences.annotationHotkey = nil
        preferences.historyHotkey = nil
        preferences.defaultSaveLocation = nil
        
        // Update timestamp
        preferences.updateTimestamp()
        
        // Remove the temporary preferences object
        context.delete(newPreferences)
        
        savePreferences()
    }
    
    // MARK: - Save Location Helpers
    
    var effectiveSaveLocation: URL? {
        // If bookmark data exists, try to resolve it
        if let bookmarkString = preferences.defaultSaveLocation,
           let bookmarkData = bookmarkString.data(using: .utf8) {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, 
                                options: .withSecurityScope,
                                relativeTo: nil,
                                bookmarkDataIsStale: &isStale)
                
                if !isStale && FileManager.default.fileExists(atPath: url.path) {
                    return url
                }
            } catch {
                logger.debug("Failed to resolve bookmark: \(error.localizedDescription)")
            }
        }
        
        // Fallback to desktop
        return try? FileManager.default.url(for: .desktopDirectory, 
                                          in: .userDomainMask, 
                                          appropriateFor: nil, 
                                          create: false)
    }
    
    var saveLocationDisplayName: String {
        if let url = effectiveSaveLocation {
            return url.lastPathComponent
        }
        return "Desktop"
    }
    
    /// Sets a custom save location using security-scoped bookmarks
    /// - Parameter url: The URL to use as the save location
    func setCustomSaveLocation(_ url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                  includingResourceValuesForKeys: nil,
                                                  relativeTo: nil)
            preferences.defaultSaveLocation = String(data: bookmarkData, encoding: .utf8)
            preferences.updateTimestamp()
            savePreferences()
            logger.info("Set custom save location: \(url.path)")
        } catch {
            logger.error("Failed to create bookmark for save location: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Window Management
    
    func showPreferencesWindow() {
        if let existingWindow = preferencesWindow {
            existingWindow.orderFront(nil)
            existingWindow.makeKey()
            return
        }
        
        createPreferencesWindow()
    }
    
    private func createPreferencesWindow() {
        let preferencesView = PreferencesView()
            .environmentObject(self)
        
        let hostingController = NSHostingController(rootView: preferencesView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "screenit Preferences"
        window.contentViewController = hostingController
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Set up window delegate
        let delegate = PreferencesWindowDelegate { [weak self] in
            self?.preferencesWindow = nil
            self?.isPreferencesWindowOpen = false
        }
        window.delegate = delegate
        
        preferencesWindow = window
        isPreferencesWindowOpen = true
        
        logger.info("Preferences window created and displayed")
    }
    
    func closePreferencesWindow() {
        preferencesWindow?.close()
        preferencesWindow = nil
        isPreferencesWindowOpen = false
    }
    
    // MARK: - Hotkey Management
    
    /// Updates the capture hotkey and validates it
    /// - Parameter hotkeyString: The new hotkey string (e.g., "cmd+shift+4")
    /// - Returns: True if the hotkey was successfully updated
    func updateCaptureHotkey(_ hotkeyString: String) -> Bool {
        logger.info("Updating capture hotkey to: \(hotkeyString)")
        
        // Validate the hotkey
        let validation = HotkeyParser.validateHotkey(hotkeyString)
        guard validation.isValid else {
            logger.error("Invalid hotkey: \(validation.message ?? "Unknown error")")
            return false
        }
        
        // Parse the hotkey to ensure it's properly formatted
        guard let config = HotkeyParser.parseHotkey(hotkeyString) else {
            logger.error("Failed to parse hotkey: \(hotkeyString)")
            return false
        }
        
        // Store the hotkey configuration as JSON
        let hotkeyData: [String: Any] = [
            "keyCode": config.keyCode,
            "modifiers": config.modifiers,
            "description": config.description,
            "originalString": HotkeyParser.configurationToString(config)
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: hotkeyData)
            preferences.captureHotkey = String(data: jsonData, encoding: .utf8)
            preferences.updateTimestamp()
            savePreferences()
            
            logger.info("Successfully updated capture hotkey to: \(config.description)")
            return true
        } catch {
            logger.error("Failed to serialize hotkey data: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Gets the current capture hotkey configuration
    /// - Returns: The parsed hotkey configuration, or default if none set
    func getCurrentCaptureHotkeyConfig() -> GlobalHotkeyManager.HotkeyConfiguration {
        if let hotkeyData = preferences.captureHotkeyData,
           let keyCode = hotkeyData["keyCode"] as? UInt32,
           let modifiers = hotkeyData["modifiers"] as? UInt32,
           let description = hotkeyData["description"] as? String {
            return GlobalHotkeyManager.HotkeyConfiguration(
                keyCode: keyCode,
                modifiers: modifiers,
                description: description
            )
        }
        
        // Return default if no valid hotkey is stored
        return GlobalHotkeyManager.HotkeyConfiguration.defaultCaptureArea
    }
    
    /// Gets the current capture hotkey as a display string
    /// - Returns: Formatted hotkey string for display (e.g., "⌘⇧4")
    var captureHotkeyDisplayString: String {
        if let _ = preferences.captureHotkey,
           let hotkeyData = preferences.captureHotkeyData,
           let originalString = hotkeyData["originalString"] as? String {
            return HotkeyParser.formatHotkeyString(originalString)
        }
        return "⌘⇧4" // Default display
    }
    
    /// Gets the current capture hotkey as a raw string
    /// - Returns: Raw hotkey string (e.g., "cmd+shift+4")
    var captureHotkeyString: String {
        if let hotkeyData = preferences.captureHotkeyData,
           let originalString = hotkeyData["originalString"] as? String {
            return originalString
        }
        return "cmd+shift+4" // Default
    }
    
    /// Resets the capture hotkey to default
    func resetCaptureHotkeyToDefault() {
        logger.info("Resetting capture hotkey to default")
        let success = updateCaptureHotkey("cmd+shift+4")
        if success {
            logger.info("Successfully reset capture hotkey to default")
        } else {
            logger.error("Failed to reset capture hotkey to default")
        }
    }
    
    /// Validates if a hotkey string is acceptable
    /// - Parameter hotkeyString: The hotkey string to validate
    /// - Returns: Validation result with details
    func validateHotkeyString(_ hotkeyString: String) -> HotkeyValidationResult {
        return HotkeyParser.validateHotkey(hotkeyString)
    }
    
    // MARK: - Validation Helpers
    
    /// Validates and clamps the history retention limit to valid range
    /// - Parameter limit: The proposed retention limit
    /// - Returns: The clamped value
    func validateHistoryRetentionLimit(_ limit: Int32) -> Int32 {
        return max(1, min(1000, limit))
    }
    
    /// Validates a hex color string
    /// - Parameter colorHex: The color string to validate
    /// - Returns: True if valid hex color format
    func validateHexColor(_ colorHex: String?) -> Bool {
        return UserPreferences.isValidHexColor(colorHex)
    }
    
    // MARK: - New Properties Validation Methods
    
    /// Validates and sets the file format preference
    /// - Parameter format: The file format to set
    /// - Returns: True if the format was set successfully
    func setFileFormat(_ format: String) -> Bool {
        let validFormats = ["PNG", "JPEG", "HEIF", "TIFF"]
        guard validFormats.contains(format) else {
            logger.warning("Invalid file format attempted: \(format)")
            return false
        }
        preferences.fileFormat = format
        return true
    }
    
    /// Validates and sets the self-timer interval
    /// - Parameter interval: The interval in seconds
    /// - Returns: True if the interval was set successfully
    func setSelfTimerInterval(_ interval: Int32) -> Bool {
        let clampedInterval = max(1, min(300, interval))
        if clampedInterval != interval {
            logger.warning("Self-timer interval clamped from \(interval) to \(clampedInterval)")
        }
        preferences.selfTimerInterval = clampedInterval
        return true
    }
    
    /// Validates and sets the overlay size
    /// - Parameter size: The overlay size multiplier
    /// - Returns: True if the size was set successfully  
    func setOverlaySize(_ size: Float) -> Bool {
        let clampedSize = max(0.1, min(3.0, size))
        if clampedSize != size {
            logger.warning("Overlay size clamped from \(size) to \(clampedSize)")
        }
        preferences.overlaySize = clampedSize
        return true
    }
    
    /// Validates and sets the auto-close interval
    /// - Parameter interval: The interval in seconds
    /// - Returns: True if the interval was set successfully
    func setAutoCloseInterval(_ interval: Int32) -> Bool {
        let clampedInterval = max(5, min(300, interval))
        if clampedInterval != interval {
            logger.warning("Auto-close interval clamped from \(interval) to \(clampedInterval)")
        }
        preferences.autoCloseInterval = clampedInterval
        return true
    }
    
    /// Validates and sets the overlay position
    /// - Parameter position: The position string
    /// - Returns: True if the position was set successfully
    func setOverlayPosition(_ position: String) -> Bool {
        let validPositions = ["Left", "Right", "Top", "Bottom", "Center"]
        guard validPositions.contains(position) else {
            logger.warning("Invalid overlay position attempted: \(position)")
            return false
        }
        preferences.overlayPositionOnScreen = position
        return true
    }
    
    /// Validates and sets the crosshair mode
    /// - Parameter mode: The crosshair mode string
    /// - Returns: True if the mode was set successfully
    func setCrosshairMode(_ mode: String) -> Bool {
        let validModes = ["Disabled", "Enabled", "Always On"]
        guard validModes.contains(mode) else {
            logger.warning("Invalid crosshair mode attempted: \(mode)")
            return false 
        }
        preferences.crosshairMode = mode
        return true
    }
    
    /// Validates and sets the history retention period
    /// - Parameter period: The retention period string
    /// - Returns: True if the period was set successfully
    func setHistoryRetentionPeriod(_ period: String) -> Bool {
        let validPeriods = ["Never", "1 day", "3 days", "1 week", "1 month"]
        guard validPeriods.contains(period) else {
            logger.warning("Invalid history retention period attempted: \(period)")
            return false
        }
        preferences.historyRetentionPeriod = period
        return true
    }
    
    /// Validates and sets the background preset
    /// - Parameter preset: The background preset string
    /// - Returns: True if the preset was set successfully
    func setBackgroundPreset(_ preset: String) -> Bool {
        let validPresets = ["None", "Blur", "Shadow", "Frame"]
        guard validPresets.contains(preset) else {
            logger.warning("Invalid background preset attempted: \(preset)")
            return false
        }
        preferences.backgroundPreset = preset
        return true
    }
    
    /// Validates all new preference properties
    /// - Returns: True if all new properties are valid
    func validateAllNewProperties() -> Bool {
        return preferences.areNewPropertiesValid
    }
}

// MARK: - Window Delegate

class PreferencesWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

// MARK: - Hotkey Helper Extensions

extension String {
    var hotkeyDisplayName: String {
        return self
            .replacingOccurrences(of: "cmd", with: "⌘")
            .replacingOccurrences(of: "shift", with: "⇧")
            .replacingOccurrences(of: "option", with: "⌥")
            .replacingOccurrences(of: "ctrl", with: "⌃")
            .replacingOccurrences(of: "+", with: "")
            .uppercased()
    }
}
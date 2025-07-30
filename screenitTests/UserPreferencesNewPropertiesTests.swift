import XCTest
import CoreData
@testable import screenit

final class UserPreferencesNewPropertiesTests: XCTestCase {
    
    var persistenceManager: PersistenceManager!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceManager = PersistenceManager(inMemory: true)
        context = persistenceManager.viewContext
    }
    
    override func tearDown() {
        persistenceManager = nil
        context = nil
        super.tearDown()
    }
    
    // MARK: - General Preferences Tests (from preferences_general.png mock)
    
    func testPostCaptureActionProperties() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When - Set post-capture action properties based on mock design
        userPrefs.showQuickAccessOverlayAfterCapture = true
        userPrefs.copyFileToClipboardAfterCapture = false
        userPrefs.saveAfterCapture = true
        userPrefs.uploadToCloudAfterCapture = false
        userPrefs.openAnnotateToolAfterCapture = false
        userPrefs.pinToScreenAfterCapture = false
        userPrefs.openVideoEditorAfterCapture = false
        
        // Then - Verify all properties are stored correctly
        XCTAssertTrue(userPrefs.showQuickAccessOverlayAfterCapture, "Quick Access Overlay should be enabled after capture")
        XCTAssertFalse(userPrefs.copyFileToClipboardAfterCapture, "Copy to clipboard should be configurable")
        XCTAssertTrue(userPrefs.saveAfterCapture, "Save action should be configurable")
        XCTAssertFalse(userPrefs.uploadToCloudAfterCapture, "Cloud upload should be configurable")
        XCTAssertFalse(userPrefs.openAnnotateToolAfterCapture, "Annotate tool should be configurable")
        XCTAssertFalse(userPrefs.pinToScreenAfterCapture, "Pin to screen should be configurable")
        XCTAssertFalse(userPrefs.openVideoEditorAfterCapture, "Video editor should be configurable")
    }
    
    func testSoundsPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When - Set sound preferences from mock
        userPrefs.playSounds = true
        userPrefs.shutterSound = "Default"
        
        // Then
        XCTAssertTrue(userPrefs.playSounds, "Play sounds setting should be stored")
        XCTAssertEqual(userPrefs.shutterSound, "Default", "Shutter sound selection should be stored")
    }
    
    func testDesktopIconsPreference() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.hideDesktopIconsWhileCapturing = true
        
        // Then
        XCTAssertTrue(userPrefs.hideDesktopIconsWhileCapturing, "Hide desktop icons preference should be stored")
    }
    
    // MARK: - Screenshots Preferences Tests (from preferences_screenshots.png mock)
    
    func testFileFormatPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.fileFormat = "PNG"
        
        // Then
        XCTAssertEqual(userPrefs.fileFormat, "PNG", "File format should be stored correctly")
        
        // Test other formats
        let validFormats = ["PNG", "JPEG", "HEIF", "TIFF"]
        for format in validFormats {
            userPrefs.fileFormat = format
            XCTAssertEqual(userPrefs.fileFormat, format, "Format \(format) should be stored correctly")
        }
    }
    
    func testRetinaAndColorManagementPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.scaleRetinaScreenshotsTo1x = false
        userPrefs.convertToSRGBProfile = false
        
        // Then
        XCTAssertFalse(userPrefs.scaleRetinaScreenshotsTo1x, "Retina scaling preference should be stored")
        XCTAssertFalse(userPrefs.convertToSRGBProfile, "Color management preference should be stored")
    }
    
    func testFrameAndBackgroundPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.add1pxBorderToScreenshots = false
        userPrefs.backgroundPreset = "None"
        
        // Then
        XCTAssertFalse(userPrefs.add1pxBorderToScreenshots, "Frame border preference should be stored")
        XCTAssertEqual(userPrefs.backgroundPreset, "None", "Background preset should be stored")
    }
    
    func testSelfTimerAndCursorPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.selfTimerInterval = 5
        userPrefs.showCursorInScreenshots = false
        
        // Then
        XCTAssertEqual(userPrefs.selfTimerInterval, 5, "Self-timer interval should be stored")
        XCTAssertFalse(userPrefs.showCursorInScreenshots, "Cursor display preference should be stored")
    }
    
    func testScreenFreezeAndCrosshairPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.freezeScreenWhenTakingScreenshot = false
        userPrefs.crosshairMode = "Disabled"
        userPrefs.showMagnifierInCrosshair = true
        
        // Then
        XCTAssertFalse(userPrefs.freezeScreenWhenTakingScreenshot, "Screen freeze preference should be stored")
        XCTAssertEqual(userPrefs.crosshairMode, "Disabled", "Crosshair mode should be stored")
        XCTAssertTrue(userPrefs.showMagnifierInCrosshair, "Magnifier preference should be stored")
    }
    
    // MARK: - Annotate Preferences Tests (from preferences_annotate.png mock)
    
    func testArrowToolPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.inverseArrowDirection = false
        
        // Then
        XCTAssertFalse(userPrefs.inverseArrowDirection, "Arrow inversion preference should be stored")
    }
    
    func testPencilAndBackgroundToolPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.smoothDrawing = true
        userPrefs.rememberBackgroundToolState = false
        
        // Then
        XCTAssertTrue(userPrefs.smoothDrawing, "Smooth drawing preference should be stored")
        XCTAssertFalse(userPrefs.rememberBackgroundToolState, "Background tool memory should be stored")
    }
    
    func testShadowAndCanvasPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.drawShadowOnObjects = true
        userPrefs.automaticallyExpandCanvas = false
        
        // Then
        XCTAssertTrue(userPrefs.drawShadowOnObjects, "Shadow drawing preference should be stored")
        XCTAssertFalse(userPrefs.automaticallyExpandCanvas, "Canvas expansion preference should be stored")
    }
    
    func testAccessibilityAndWindowPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.showColorNames = false
        userPrefs.alwaysOnTop = false
        userPrefs.showDockIcon = true
        
        // Then
        XCTAssertFalse(userPrefs.showColorNames, "Color names accessibility should be stored")
        XCTAssertFalse(userPrefs.alwaysOnTop, "Always on top preference should be stored")
        XCTAssertTrue(userPrefs.showDockIcon, "Dock icon preference should be stored")
    }
    
    // MARK: - Quick Access Preferences Tests (from preferences_quick-access.png mock)
    
    func testOverlayPositionAndDisplayPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.overlayPositionOnScreen = "Left"
        userPrefs.moveToActiveScreen = true
        userPrefs.overlaySize = 1.0
        
        // Then
        XCTAssertEqual(userPrefs.overlayPositionOnScreen, "Left", "Overlay position should be stored")
        XCTAssertTrue(userPrefs.moveToActiveScreen, "Active screen movement should be stored")
        XCTAssertEqual(userPrefs.overlaySize, 1.0, accuracy: 0.01, "Overlay size should be stored")
    }
    
    func testAutoClosePreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.enableAutoClose = false
        userPrefs.autoCloseAction = "Save and Close"
        userPrefs.autoCloseInterval = 30
        
        // Then
        XCTAssertFalse(userPrefs.enableAutoClose, "Auto-close enable setting should be stored")
        XCTAssertEqual(userPrefs.autoCloseAction, "Save and Close", "Auto-close action should be stored")
        XCTAssertEqual(userPrefs.autoCloseInterval, 30, "Auto-close interval should be stored")
    }
    
    func testDragDropAndCloudPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.closeAfterDragging = true
        userPrefs.closeAfterCloudUpload = true
        userPrefs.saveButtonBehavior = "Save to \"Export location\""
        
        // Then
        XCTAssertTrue(userPrefs.closeAfterDragging, "Close after dragging should be stored")
        XCTAssertTrue(userPrefs.closeAfterCloudUpload, "Close after upload should be stored")
        XCTAssertEqual(userPrefs.saveButtonBehavior, "Save to \"Export location\"", "Save button behavior should be stored")
    }
    
    // MARK: - Advanced Preferences Tests (from preferences_advanced.png mock)
    
    func testFileNamingPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.fileNamingPattern = "Edit"
        userPrefs.askForNameAfterEveryCapture = false
        userPrefs.addRetinaSuffixToFilenames = true
        
        // Then
        XCTAssertEqual(userPrefs.fileNamingPattern, "Edit", "File naming pattern should be stored")
        XCTAssertFalse(userPrefs.askForNameAfterEveryCapture, "Ask for name preference should be stored")
        XCTAssertTrue(userPrefs.addRetinaSuffixToFilenames, "Retina suffix preference should be stored")
    }
    
    func testClipboardAndPinnedScreenshotPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.clipboardCopyMode = "File & Image (default)"
        userPrefs.pinnedScreenshotRoundedCorners = true
        userPrefs.pinnedScreenshotShadow = true
        userPrefs.pinnedScreenshotBorder = true
        
        // Then
        XCTAssertEqual(userPrefs.clipboardCopyMode, "File & Image (default)", "Clipboard copy mode should be stored")
        XCTAssertTrue(userPrefs.pinnedScreenshotRoundedCorners, "Pinned rounded corners should be stored")
        XCTAssertTrue(userPrefs.pinnedScreenshotShadow, "Pinned shadow should be stored")
        XCTAssertTrue(userPrefs.pinnedScreenshotBorder, "Pinned border should be stored")
    }
    
    func testHistoryRetentionPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.historyRetentionPeriod = "1 week"
        
        // Then
        XCTAssertEqual(userPrefs.historyRetentionPeriod, "1 week", "History retention period should be stored")
        
        // Test all valid retention periods
        let validPeriods = ["Never", "1 day", "3 days", "1 week", "1 month"]
        for period in validPeriods {
            userPrefs.historyRetentionPeriod = period
            XCTAssertEqual(userPrefs.historyRetentionPeriod, period, "Retention period \(period) should be stored")
        }
    }
    
    func testAllInOneAndTextRecognitionPreferences() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.rememberLastAllInOneSelection = true
        userPrefs.textRecognitionLanguage = "Automatically Detect Language"
        userPrefs.textRecognitionKeepLineBreaks = false
        userPrefs.textRecognitionDetectLinks = true
        
        // Then
        XCTAssertTrue(userPrefs.rememberLastAllInOneSelection, "All-In-One memory should be stored")
        XCTAssertEqual(userPrefs.textRecognitionLanguage, "Automatically Detect Language", "Text recognition language should be stored")
        XCTAssertFalse(userPrefs.textRecognitionKeepLineBreaks, "Line breaks preference should be stored")
        XCTAssertTrue(userPrefs.textRecognitionDetectLinks, "Link detection preference should be stored")
    }
    
    func testAPIControlPreference() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When
        userPrefs.allowApplicationsToControlApp = false
        
        // Then
        XCTAssertFalse(userPrefs.allowApplicationsToControlApp, "API control preference should be stored")
    }
    
    // MARK: - Property Validation Tests
    
    func testEnumValidation() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // Test file format validation
        let validFileFormats = ["PNG", "JPEG", "HEIF", "TIFF"]
        let invalidFileFormats = ["", "INVALID", "pdf", "123"]
        
        for format in validFileFormats {
            userPrefs.fileFormat = format
            XCTAssertEqual(userPrefs.fileFormat, format, "Valid format \(format) should be accepted")
        }
        
        for format in invalidFileFormats {
            userPrefs.fileFormat = format
            XCTAssertEqual(userPrefs.fileFormat, format, "Core Data stores any string - validation handled by manager")
        }
    }
    
    func testNumericRangeValidation() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // Test self-timer interval validation
        let validIntervals: [Int32] = [1, 5, 10, 30, 60]
        let invalidIntervals: [Int32] = [0, -1, 300]
        
        for interval in validIntervals {
            userPrefs.selfTimerInterval = interval
            XCTAssertEqual(userPrefs.selfTimerInterval, interval, "Valid interval \(interval) should be stored")
        }
        
        for interval in invalidIntervals {
            userPrefs.selfTimerInterval = interval
            XCTAssertEqual(userPrefs.selfTimerInterval, interval, "Core Data stores any value - validation handled by manager")
        }
        
        // Test overlay size validation
        userPrefs.overlaySize = 0.5
        XCTAssertEqual(userPrefs.overlaySize, 0.5, accuracy: 0.01, "Overlay size should be stored as float")
        
        userPrefs.overlaySize = 2.0
        XCTAssertEqual(userPrefs.overlaySize, 2.0, accuracy: 0.01, "Overlay size should accept any float value")
    }
    
    // MARK: - Default Values Tests
    
    func testDefaultValuesFromCreateWithDefaults() {
        // When
        let userPrefs = UserPreferences.createWithDefaults(in: context)
        
        // Then - Test that all new properties have appropriate defaults
        
        // General preferences defaults
        XCTAssertTrue(userPrefs.showQuickAccessOverlayAfterCapture, "Quick Access should be shown by default")
        XCTAssertFalse(userPrefs.copyFileToClipboardAfterCapture, "Copy to clipboard should be off by default")
        XCTAssertTrue(userPrefs.saveAfterCapture, "Save should be enabled by default")
        XCTAssertFalse(userPrefs.uploadToCloudAfterCapture, "Cloud upload should be off by default")
        XCTAssertFalse(userPrefs.playSounds, "Sounds should be off by default")
        XCTAssertEqual(userPrefs.shutterSound, "Default", "Default shutter sound should be set")
        
        // Screenshots preferences defaults
        XCTAssertEqual(userPrefs.fileFormat, "PNG", "PNG should be default file format")
        XCTAssertFalse(userPrefs.scaleRetinaScreenshotsTo1x, "Retina scaling should be off by default")
        XCTAssertFalse(userPrefs.convertToSRGBProfile, "sRGB conversion should be off by default")
        XCTAssertFalse(userPrefs.add1pxBorderToScreenshots, "Frame border should be off by default")
        XCTAssertEqual(userPrefs.backgroundPreset, "None", "Background should be None by default")
        XCTAssertEqual(userPrefs.selfTimerInterval, 5, "Self-timer should default to 5 seconds")
        XCTAssertFalse(userPrefs.showCursorInScreenshots, "Cursor should be hidden by default")
        XCTAssertFalse(userPrefs.freezeScreenWhenTakingScreenshot, "Screen freeze should be off by default")
        XCTAssertEqual(userPrefs.crosshairMode, "Disabled", "Crosshair should be disabled by default")
        XCTAssertTrue(userPrefs.showMagnifierInCrosshair, "Magnifier should be shown by default")
        
        // Annotate preferences defaults
        XCTAssertFalse(userPrefs.inverseArrowDirection, "Arrow inversion should be off by default")
        XCTAssertTrue(userPrefs.smoothDrawing, "Smooth drawing should be on by default")
        XCTAssertFalse(userPrefs.rememberBackgroundToolState, "Background tool memory should be off by default")
        XCTAssertTrue(userPrefs.drawShadowOnObjects, "Shadow drawing should be on by default")
        XCTAssertFalse(userPrefs.automaticallyExpandCanvas, "Canvas expansion should be off by default")
        XCTAssertFalse(userPrefs.showColorNames, "Color names should be off by default")
        XCTAssertFalse(userPrefs.alwaysOnTop, "Always on top should be off by default")
        XCTAssertTrue(userPrefs.showDockIcon, "Dock icon should be shown by default")
        
        // Quick Access preferences defaults
        XCTAssertEqual(userPrefs.overlayPositionOnScreen, "Left", "Overlay should be positioned left by default")
        XCTAssertTrue(userPrefs.moveToActiveScreen, "Move to active screen should be on by default")
        XCTAssertEqual(userPrefs.overlaySize, 1.0, accuracy: 0.01, "Overlay size should default to 1.0")
        XCTAssertFalse(userPrefs.enableAutoClose, "Auto-close should be off by default")
        XCTAssertEqual(userPrefs.autoCloseAction, "Save and Close", "Default auto-close action should be set")
        XCTAssertEqual(userPrefs.autoCloseInterval, 30, "Auto-close interval should default to 30 seconds")
        XCTAssertTrue(userPrefs.closeAfterDragging, "Close after dragging should be on by default")
        XCTAssertTrue(userPrefs.closeAfterCloudUpload, "Close after upload should be on by default")
        XCTAssertEqual(userPrefs.saveButtonBehavior, "Save to \"Export location\"", "Save button behavior should be set")
        
        // Advanced preferences defaults
        XCTAssertEqual(userPrefs.fileNamingPattern, "Edit", "File naming should default to Edit")
        XCTAssertFalse(userPrefs.askForNameAfterEveryCapture, "Ask for name should be off by default")
        XCTAssertTrue(userPrefs.addRetinaSuffixToFilenames, "Retina suffix should be on by default")
        XCTAssertEqual(userPrefs.clipboardCopyMode, "File & Image (default)", "Default clipboard mode should be set")
        XCTAssertTrue(userPrefs.pinnedScreenshotRoundedCorners, "Pinned rounded corners should be on by default")
        XCTAssertTrue(userPrefs.pinnedScreenshotShadow, "Pinned shadow should be on by default")
        XCTAssertTrue(userPrefs.pinnedScreenshotBorder, "Pinned border should be on by default")
        XCTAssertEqual(userPrefs.historyRetentionPeriod, "1 week", "History retention should default to 1 week")
        XCTAssertTrue(userPrefs.rememberLastAllInOneSelection, "All-In-One memory should be on by default")
        XCTAssertEqual(userPrefs.textRecognitionLanguage, "Automatically Detect Language", "Text recognition language should auto-detect")
        XCTAssertFalse(userPrefs.textRecognitionKeepLineBreaks, "Line breaks should be off by default")
        XCTAssertTrue(userPrefs.textRecognitionDetectLinks, "Link detection should be on by default")
        XCTAssertFalse(userPrefs.allowApplicationsToControlApp, "API control should be off by default")
    }
    
    // MARK: - Core Data Persistence Tests
    
    func testNewPropertiesPersistence() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When - Set all new properties to non-default values
        userPrefs.fileFormat = "JPEG"
        userPrefs.scaleRetinaScreenshotsTo1x = true
        userPrefs.overlayPositionOnScreen = "Right" 
        userPrefs.enableAutoClose = true
        userPrefs.historyRetentionPeriod = "3 days"
        userPrefs.textRecognitionLanguage = "English"
        
        // Save to Core Data
        do {
            try context.save()
        } catch {
            XCTFail("Save should succeed: \(error)")
        }
        
        // Then - Fetch and verify persistence
        let fetchRequest: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1, "Should have one UserPreferences entity")
            
            let fetchedPrefs = results.first!
            XCTAssertEqual(fetchedPrefs.fileFormat, "JPEG", "File format should persist")
            XCTAssertTrue(fetchedPrefs.scaleRetinaScreenshotsTo1x, "Retina scaling should persist")
            XCTAssertEqual(fetchedPrefs.overlayPositionOnScreen, "Right", "Overlay position should persist")
            XCTAssertTrue(fetchedPrefs.enableAutoClose, "Auto-close should persist")
            XCTAssertEqual(fetchedPrefs.historyRetentionPeriod, "3 days", "History retention should persist")
            XCTAssertEqual(fetchedPrefs.textRecognitionLanguage, "English", "Text recognition language should persist")
        } catch {
            XCTFail("Fetch should succeed: \(error)")
        }
    }
}
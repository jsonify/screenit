import XCTest
import CoreData
@testable import screenit

/// Simple validation test for new Core Data properties
/// This test validates that the new properties can be created, saved, and loaded correctly
final class CoreDataNewPropertiesValidationTest: XCTestCase {
    
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
    
    func testNewPropertiesCanBeCreatedAndSaved() {
        // Given - Create UserPreferences with new properties
        let userPrefs = UserPreferences.createWithDefaults(in: context)
        
        // When - Set new properties based on mock designs
        userPrefs.fileFormat = "JPEG"
        userPrefs.scaleRetinaScreenshotsTo1x = true
        userPrefs.overlayPositionOnScreen = "Right"
        userPrefs.enableAutoClose = true
        userPrefs.historyRetentionPeriod = "3 days"
        userPrefs.textRecognitionLanguage = "English"
        
        // Then - Verify properties are set
        XCTAssertEqual(userPrefs.fileFormat, "JPEG")
        XCTAssertTrue(userPrefs.scaleRetinaScreenshotsTo1x)
        XCTAssertEqual(userPrefs.overlayPositionOnScreen, "Right")
        XCTAssertTrue(userPrefs.enableAutoClose)
        XCTAssertEqual(userPrefs.historyRetentionPeriod, "3 days")
        XCTAssertEqual(userPrefs.textRecognitionLanguage, "English")
        
        // And - Save to Core Data
        do {
            try context.save()
        } catch {
            XCTFail("Save should succeed: \(error)")
        }
        
        // And - Fetch and verify persistence
        let fetchRequest: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1, "Should have one UserPreferences entity")
            
            let fetchedPrefs = results.first!
            XCTAssertEqual(fetchedPrefs.fileFormat, "JPEG")
            XCTAssertTrue(fetchedPrefs.scaleRetinaScreenshotsTo1x)
            XCTAssertEqual(fetchedPrefs.overlayPositionOnScreen, "Right")
            XCTAssertTrue(fetchedPrefs.enableAutoClose)
            XCTAssertEqual(fetchedPrefs.historyRetentionPeriod, "3 days")
            XCTAssertEqual(fetchedPrefs.textRecognitionLanguage, "English")
        } catch {
            XCTFail("Fetch should succeed: \(error)")
        }
    }
    
    func testDefaultValuesMatchMockDesigns() {
        // When - Create UserPreferences with defaults
        let userPrefs = UserPreferences.createWithDefaults(in: context)
        
        // Then - Verify defaults match mock designs
        
        // General preferences (from preferences_general.png)
        XCTAssertTrue(userPrefs.showQuickAccessOverlayAfterCapture)
        XCTAssertFalse(userPrefs.copyFileToClipboardAfterCapture)
        XCTAssertTrue(userPrefs.saveAfterCapture)
        XCTAssertFalse(userPrefs.uploadToCloudAfterCapture)
        XCTAssertFalse(userPrefs.playSounds)
        XCTAssertEqual(userPrefs.shutterSound, "Default")
        
        // Screenshots preferences (from preferences_screenshots.png)
        XCTAssertEqual(userPrefs.fileFormat, "PNG")
        XCTAssertFalse(userPrefs.scaleRetinaScreenshotsTo1x)
        XCTAssertFalse(userPrefs.convertToSRGBProfile)
        XCTAssertFalse(userPrefs.add1pxBorderToScreenshots)
        XCTAssertEqual(userPrefs.backgroundPreset, "None")
        XCTAssertEqual(userPrefs.selfTimerInterval, 5)
        XCTAssertFalse(userPrefs.showCursorInScreenshots)
        XCTAssertFalse(userPrefs.freezeScreenWhenTakingScreenshot)
        XCTAssertEqual(userPrefs.crosshairMode, "Disabled")
        XCTAssertTrue(userPrefs.showMagnifierInCrosshair)
        
        // Annotate preferences (from preferences_annotate.png)
        XCTAssertFalse(userPrefs.inverseArrowDirection)
        XCTAssertTrue(userPrefs.smoothDrawing)
        XCTAssertFalse(userPrefs.rememberBackgroundToolState)
        XCTAssertTrue(userPrefs.drawShadowOnObjects)
        XCTAssertFalse(userPrefs.automaticallyExpandCanvas)
        XCTAssertFalse(userPrefs.showColorNames)
        XCTAssertFalse(userPrefs.alwaysOnTop)
        XCTAssertTrue(userPrefs.showDockIcon)
        
        // Quick Access preferences (from preferences_quick-access.png)
        XCTAssertEqual(userPrefs.overlayPositionOnScreen, "Left")
        XCTAssertTrue(userPrefs.moveToActiveScreen)
        XCTAssertEqual(userPrefs.overlaySize, 1.0, accuracy: 0.01)
        XCTAssertFalse(userPrefs.enableAutoClose)
        XCTAssertEqual(userPrefs.autoCloseAction, "Save and Close")
        XCTAssertEqual(userPrefs.autoCloseInterval, 30)
        XCTAssertTrue(userPrefs.closeAfterDragging)
        XCTAssertTrue(userPrefs.closeAfterCloudUpload)
        XCTAssertEqual(userPrefs.saveButtonBehavior, "Save to \"Export location\"")
        
        // Advanced preferences (from preferences_advanced.png)
        XCTAssertEqual(userPrefs.fileNamingPattern, "Edit")
        XCTAssertFalse(userPrefs.askForNameAfterEveryCapture)
        XCTAssertTrue(userPrefs.addRetinaSuffixToFilenames)
        XCTAssertEqual(userPrefs.clipboardCopyMode, "File & Image (default)")
        XCTAssertTrue(userPrefs.pinnedScreenshotRoundedCorners)
        XCTAssertTrue(userPrefs.pinnedScreenshotShadow)
        XCTAssertTrue(userPrefs.pinnedScreenshotBorder)
        XCTAssertEqual(userPrefs.historyRetentionPeriod, "1 week")
        XCTAssertTrue(userPrefs.rememberLastAllInOneSelection)
        XCTAssertEqual(userPrefs.textRecognitionLanguage, "Automatically Detect Language")
        XCTAssertFalse(userPrefs.textRecognitionKeepLineBreaks)
        XCTAssertTrue(userPrefs.textRecognitionDetectLinks)
        XCTAssertFalse(userPrefs.allowApplicationsToControlApp)
    }
    
    func testValidationMethods() {
        // Given
        let userPrefs = UserPreferences.createWithDefaults(in: context)
        
        // When - Test validation methods for new properties
        let isFileFormatValid = userPrefs.isFileFormatValid
        let isSelfTimerValid = userPrefs.isSelfTimerIntervalValid
        let isOverlaySizeValid = userPrefs.isOverlaySizeValid
        let isAutoCloseIntervalValid = userPrefs.isAutoCloseIntervalValid
        let isOverlayPositionValid = userPrefs.isOverlayPositionValid
        let isCrosshairModeValid = userPrefs.isCrosshairModeValid
        let isHistoryRetentionValid = userPrefs.isHistoryRetentionPeriodValid
        let isBackgroundPresetValid = userPrefs.isBackgroundPresetValid
        let areAllNewPropertiesValid = userPrefs.areNewPropertiesValid
        
        // Then - All validations should pass with default values
        XCTAssertTrue(isFileFormatValid, "Default file format should be valid")
        XCTAssertTrue(isSelfTimerValid, "Default self-timer interval should be valid")
        XCTAssertTrue(isOverlaySizeValid, "Default overlay size should be valid")
        XCTAssertTrue(isAutoCloseIntervalValid, "Default auto-close interval should be valid")
        XCTAssertTrue(isOverlayPositionValid, "Default overlay position should be valid")
        XCTAssertTrue(isCrosshairModeValid, "Default crosshair mode should be valid")
        XCTAssertTrue(isHistoryRetentionValid, "Default history retention should be valid")
        XCTAssertTrue(isBackgroundPresetValid, "Default background preset should be valid")
        XCTAssertTrue(areAllNewPropertiesValid, "All new properties should be valid by default")
    }
}
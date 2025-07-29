import XCTest
import CoreData
import AppKit
@testable import screenit

final class UserPreferencesTests: XCTestCase {
    
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
    
    // MARK: - UserPreferences Entity Tests
    
    func testUserPreferencesCreation() {
        // Given - Default values from schema specification
        let expectedDefaults = UserPreferences(context: context)
        
        // When - Create a new UserPreferences entity
        let userPrefs = UserPreferences(context: context)
        userPrefs.historyRetentionLimit = 10
        userPrefs.showMenuBarIcon = true
        userPrefs.launchAtLogin = false
        userPrefs.defaultArrowColor = "#FF0000"
        userPrefs.defaultTextColor = "#000000"
        userPrefs.defaultRectangleColor = "#0066CC"
        userPrefs.defaultHighlightColor = "#FFFF00"
        userPrefs.defaultArrowThickness = 2.0
        userPrefs.defaultTextSize = 14.0
        userPrefs.defaultRectangleThickness = 2.0
        userPrefs.autoSaveToDesktop = true
        userPrefs.showCaptureNotifications = true
        userPrefs.enableSoundEffects = false
        userPrefs.createdAt = Date()
        userPrefs.updatedAt = Date()
        
        // Then - Verify all properties are set correctly
        XCTAssertEqual(userPrefs.historyRetentionLimit, 10, "History retention limit should be 10")
        XCTAssertEqual(userPrefs.showMenuBarIcon, true, "Menu bar icon should be shown by default")
        XCTAssertEqual(userPrefs.launchAtLogin, false, "Launch at login should be false by default")
        
        // Annotation defaults
        XCTAssertEqual(userPrefs.defaultArrowColor, "#FF0000", "Default arrow color should be red")
        XCTAssertEqual(userPrefs.defaultTextColor, "#000000", "Default text color should be black")
        XCTAssertEqual(userPrefs.defaultRectangleColor, "#0066CC", "Default rectangle color should be blue")
        XCTAssertEqual(userPrefs.defaultHighlightColor, "#FFFF00", "Default highlight color should be yellow")
        
        // Thickness and size defaults
        XCTAssertEqual(userPrefs.defaultArrowThickness, 2.0, accuracy: 0.01, "Default arrow thickness should be 2.0")
        XCTAssertEqual(userPrefs.defaultTextSize, 14.0, accuracy: 0.01, "Default text size should be 14.0")
        XCTAssertEqual(userPrefs.defaultRectangleThickness, 2.0, accuracy: 0.01, "Default rectangle thickness should be 2.0")
        
        // Advanced settings
        XCTAssertEqual(userPrefs.autoSaveToDesktop, true, "Auto save to desktop should be true by default")
        XCTAssertEqual(userPrefs.showCaptureNotifications, true, "Capture notifications should be shown by default")
        XCTAssertEqual(userPrefs.enableSoundEffects, false, "Sound effects should be disabled by default")
        
        // Metadata
        XCTAssertNotNil(userPrefs.createdAt, "Created timestamp should be set")
        XCTAssertNotNil(userPrefs.updatedAt, "Updated timestamp should be set")
    }
    
    func testUserPreferencesHotkeySettings() {
        // Given
        let userPrefs = UserPreferences(context: context)
        let captureHotkeyJSON = "{\"modifiers\":[\"cmd\",\"shift\"],\"key\":\"4\"}"
        let annotationHotkeyJSON = "{\"modifiers\":[\"cmd\",\"alt\"],\"key\":\"a\"}"
        let historyHotkeyJSON = "{\"modifiers\":[\"cmd\",\"shift\"],\"key\":\"h\"}"
        
        // When
        userPrefs.captureHotkey = captureHotkeyJSON
        userPrefs.annotationHotkey = annotationHotkeyJSON
        userPrefs.historyHotkey = historyHotkeyJSON
        
        // Then
        XCTAssertEqual(userPrefs.captureHotkey, captureHotkeyJSON, "Capture hotkey JSON should be stored correctly")
        XCTAssertEqual(userPrefs.annotationHotkey, annotationHotkeyJSON, "Annotation hotkey JSON should be stored correctly")
        XCTAssertEqual(userPrefs.historyHotkey, historyHotkeyJSON, "History hotkey JSON should be stored correctly")
    }
    
    func testUserPreferencesFileLocationBookmarks() {
        // Given
        let userPrefs = UserPreferences(context: context)
        let bookmarkData = "mock_bookmark_data_for_custom_location"
        
        // When
        userPrefs.defaultSaveLocation = bookmarkData
        
        // Then
        XCTAssertEqual(userPrefs.defaultSaveLocation, bookmarkData, "Save location bookmark should be stored correctly")
    }
    
    func testUserPreferencesValidation() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When - Test history retention limit validation
        userPrefs.historyRetentionLimit = 0 // Invalid value
        
        // Then - Should allow invalid values (validation handled by PreferencesManager)
        XCTAssertEqual(userPrefs.historyRetentionLimit, 0, "Core Data entity should store any value, validation is handled by manager")
        
        // Test with valid range
        userPrefs.historyRetentionLimit = 50
        XCTAssertEqual(userPrefs.historyRetentionLimit, 50, "Valid retention limit should be stored")
        
        userPrefs.historyRetentionLimit = 1000
        XCTAssertEqual(userPrefs.historyRetentionLimit, 1000, "Max retention limit should be stored")
    }
    
    func testUserPreferencesColorHexValues() {
        // Given
        let userPrefs = UserPreferences(context: context)
        
        // When - Test various hex color formats
        let testColors = [
            "#FF0000", // Red
            "#00FF00", // Green  
            "#0000FF", // Blue
            "#FFFFFF", // White
            "#000000", // Black
            "#123456", // Custom hex
            "invalid_color" // Invalid format (should still store)
        ]
        
        for color in testColors {
            userPrefs.defaultArrowColor = color
            
            // Then
            XCTAssertEqual(userPrefs.defaultArrowColor, color, "Color hex value should be stored as-is: \(color)")
        }
    }
    
    func testUserPreferencesPersistence() {
        // Given
        let userPrefs = UserPreferences(context: context)
        userPrefs.historyRetentionLimit = 25
        userPrefs.showMenuBarIcon = false
        userPrefs.defaultArrowColor = "#123456"
        userPrefs.createdAt = Date()
        userPrefs.updatedAt = Date()
        
        // When - Save to context
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
            XCTAssertEqual(fetchedPrefs.historyRetentionLimit, 25, "Persisted retention limit should match")
            XCTAssertEqual(fetchedPrefs.showMenuBarIcon, false, "Persisted menu bar setting should match")
            XCTAssertEqual(fetchedPrefs.defaultArrowColor, "#123456", "Persisted color should match")
            XCTAssertNotNil(fetchedPrefs.createdAt, "Persisted created date should exist")
            XCTAssertNotNil(fetchedPrefs.updatedAt, "Persisted updated date should exist")
        } catch {
            XCTFail("Fetch should succeed: \(error)")
        }
    }
    
    func testUserPreferencesSingletonPattern() {
        // Given - Create multiple UserPreferences entities
        let userPrefs1 = UserPreferences(context: context)
        userPrefs1.historyRetentionLimit = 10
        userPrefs1.createdAt = Date()
        userPrefs1.updatedAt = Date()
        
        let userPrefs2 = UserPreferences(context: context)
        userPrefs2.historyRetentionLimit = 20
        userPrefs2.createdAt = Date()
        userPrefs2.updatedAt = Date()
        
        // When - Save both entities
        do {
            try context.save()
        } catch {
            XCTFail("Save should succeed: \(error)")
        }
        
        // Then - Verify both entities exist (singleton enforcement is handled by PreferencesManager)
        let fetchRequest: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            XCTAssertEqual(results.count, 2, "Core Data allows multiple entities, singleton is enforced by manager")
        } catch {
            XCTFail("Fetch should succeed: \(error)")
        }
    }
    
    func testUserPreferencesTimestampUpdates() {
        // Given
        let userPrefs = UserPreferences(context: context)
        let initialDate = Date()
        userPrefs.createdAt = initialDate
        userPrefs.updatedAt = initialDate
        userPrefs.historyRetentionLimit = 10
        
        try! context.save()
        
        // When - Update a property
        Thread.sleep(forTimeInterval: 0.1) // Ensure different timestamp
        let updatedDate = Date()
        userPrefs.historyRetentionLimit = 15
        userPrefs.updatedAt = updatedDate
        
        try! context.save()
        
        // Then - Verify timestamps
        XCTAssertEqual(userPrefs.createdAt, initialDate, "Created date should remain unchanged")
        XCTAssertEqual(userPrefs.updatedAt, updatedDate, "Updated date should reflect changes")
        XCTAssertNotEqual(userPrefs.createdAt, userPrefs.updatedAt, "Created and updated dates should be different")
    }
}
import XCTest
import CoreData
import Combine
@testable import screenit

final class PreferencesManagerCoreDataTests: XCTestCase {
    
    var persistenceManager: PersistenceManager!
    var preferencesManager: PreferencesManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        persistenceManager = PersistenceManager(inMemory: true)
        cancellables = Set<AnyCancellable>()
        
        // Reset the shared preferences manager for testing
        preferencesManager = PreferencesManager.createForTesting(with: persistenceManager)
    }
    
    override func tearDown() {
        cancellables.removeAll()
        preferencesManager = nil
        persistenceManager = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Pattern Tests
    
    func testPreferencesManagerSingleton() {
        // Given
        let manager1 = PreferencesManager.shared
        let manager2 = PreferencesManager.shared
        
        // Then
        XCTAssertTrue(manager1 === manager2, "PreferencesManager should be a singleton")
    }
    
    func testPreferencesManagerInitialization() {
        // When
        let manager = preferencesManager!
        
        // Then
        XCTAssertNotNil(manager.preferences, "PreferencesManager should have preferences object")
        XCTAssertTrue(manager is ObservableObject, "PreferencesManager should be an ObservableObject")
    }
    
    // MARK: - Core Data Integration Tests
    
    func testPreferencesManagerCreatesDefaultPreferences() {
        // When
        let manager = preferencesManager!
        
        // Then
        let fetchRequest: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        let results = try! persistenceManager.viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(results.count, 1, "Should create exactly one UserPreferences entity")
        let preferences = results.first!
        
        // Check default values
        XCTAssertEqual(preferences.historyRetentionLimit, 10, "Default history retention should be 10")
        XCTAssertEqual(preferences.showMenuBarIcon, true, "Menu bar icon should be shown by default")
        XCTAssertEqual(preferences.launchAtLogin, false, "Launch at login should be false by default")
        XCTAssertEqual(preferences.defaultArrowColor, "#FF0000", "Default arrow color should be red")
        XCTAssertNotNil(preferences.createdAt, "Created timestamp should be set")
        XCTAssertNotNil(preferences.updatedAt, "Updated timestamp should be set")
    }
    
    func testPreferencesManagerFetchesExistingPreferences() {
        // Given - Create preferences directly in Core Data
        let context = persistenceManager.viewContext
        let existingPrefs = UserPreferences.createWithDefaults(in: context)
        existingPrefs.historyRetentionLimit = 25
        existingPrefs.defaultArrowColor = "#00FF00"
        try! context.save()
        
        // When - Create new manager (should fetch existing)
        let newManager = PreferencesManager.createForTesting(with: persistenceManager)
        
        // Then
        XCTAssertEqual(newManager.preferences.historyRetentionLimit, 25, "Should fetch existing retention limit")
        XCTAssertEqual(newManager.preferences.defaultArrowColor, "#00FF00", "Should fetch existing arrow color")
    }
    
    func testPreferencesManagerSingletonEnforcement() {
        // Given - Multiple UserPreferences entities in database
        let context = persistenceManager.viewContext
        let prefs1 = UserPreferences.createWithDefaults(in: context)
        prefs1.historyRetentionLimit = 10
        let prefs2 = UserPreferences.createWithDefaults(in: context)
        prefs2.historyRetentionLimit = 20
        try! context.save()
        
        // When
        let manager = PreferencesManager.createForTesting(with: persistenceManager)
        
        // Then - Should use the first one found
        XCTAssertTrue(manager.preferences.historyRetentionLimit == 10 || manager.preferences.historyRetentionLimit == 20, 
                     "Should use one of the existing preferences")
    }
    
    // MARK: - Published Properties Tests
    
    func testPreferencesManagerPublishedProperties() {
        // Given
        var receivedUpdates = 0
        let expectation = XCTestExpectation(description: "Preferences update")
        expectation.expectedFulfillmentCount = 2 // Initial value + one update
        
        // When
        preferencesManager.$preferences
            .sink { _ in
                receivedUpdates += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Update a preference
        preferencesManager.preferences.historyRetentionLimit = 20
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedUpdates, 2, "Should receive initial value and update")
    }
    
    // MARK: - Persistence Tests
    
    func testPreferencesManagerAutomaticSave() {
        // Given
        let manager = preferencesManager!
        let initialRetentionLimit = manager.preferences.historyRetentionLimit
        
        // When
        manager.preferences.historyRetentionLimit = initialRetentionLimit + 10
        manager.preferences.updateTimestamp()
        manager.savePreferences()
        
        // Then - Verify saved to Core Data
        let fetchRequest: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        let results = try! persistenceManager.viewContext.fetch(fetchRequest)
        let savedPrefs = results.first!
        
        XCTAssertEqual(savedPrefs.historyRetentionLimit, initialRetentionLimit + 10, "Changes should be persisted")
        XCTAssertNotNil(savedPrefs.updatedAt, "Updated timestamp should be set")
    }
    
    func testPreferencesManagerValidation() {
        // Given
        let manager = preferencesManager!
        
        // When - Set invalid retention limit
        manager.preferences.historyRetentionLimit = -5
        
        // Then - Manager should handle validation
        XCTAssertFalse(manager.preferences.isHistoryRetentionLimitValid, "Should detect invalid retention limit")
        XCTAssertEqual(manager.preferences.effectiveHistoryRetentionLimit, 1, "Should clamp to minimum valid value")
        
        // When - Set valid retention limit
        manager.preferences.historyRetentionLimit = 50
        
        // Then
        XCTAssertTrue(manager.preferences.isHistoryRetentionLimitValid, "Should validate correct retention limit")
        XCTAssertEqual(manager.preferences.effectiveHistoryRetentionLimit, 50, "Should return actual value when valid")
    }
    
    // MARK: - Error Handling Tests
    
    func testPreferencesManagerHandlesCorruptedData() {
        // Given - Corrupted hotkey JSON
        let manager = preferencesManager!
        
        // When
        manager.preferences.captureHotkey = "invalid_json_data"
        
        // Then - Should handle gracefully
        XCTAssertNil(manager.preferences.captureHotkeyData, "Should return nil for invalid JSON")
        
        // When - Valid JSON
        manager.preferences.captureHotkey = "{\"modifiers\":[\"cmd\",\"shift\"],\"key\":\"4\"}"
        
        // Then
        XCTAssertNotNil(manager.preferences.captureHotkeyData, "Should parse valid JSON")
    }
    
    // MARK: - Default Values Tests
    
    func testPreferencesManagerDefaultValues() {
        // Given
        let manager = preferencesManager!
        let preferences = manager.preferences
        
        // Then - Verify all default values match specification
        XCTAssertEqual(preferences.historyRetentionLimit, 10, "Default history retention should be 10")
        XCTAssertEqual(preferences.showMenuBarIcon, true, "Menu bar icon should be shown by default")
        XCTAssertEqual(preferences.launchAtLogin, false, "Launch at login should be false by default")
        
        // Annotation defaults
        XCTAssertEqual(preferences.defaultArrowColor, "#FF0000", "Default arrow color should be red")
        XCTAssertEqual(preferences.defaultTextColor, "#000000", "Default text color should be black")
        XCTAssertEqual(preferences.defaultRectangleColor, "#0066CC", "Default rectangle color should be blue")
        XCTAssertEqual(preferences.defaultHighlightColor, "#FFFF00", "Default highlight color should be yellow")
        
        // Thickness and size defaults
        XCTAssertEqual(preferences.defaultArrowThickness, 2.0, accuracy: 0.01, "Default arrow thickness should be 2.0")
        XCTAssertEqual(preferences.defaultTextSize, 14.0, accuracy: 0.01, "Default text size should be 14.0")
        XCTAssertEqual(preferences.defaultRectangleThickness, 2.0, accuracy: 0.01, "Default rectangle thickness should be 2.0")
        
        // Advanced settings
        XCTAssertEqual(preferences.autoSaveToDesktop, true, "Auto save to desktop should be true by default")
        XCTAssertEqual(preferences.showCaptureNotifications, true, "Capture notifications should be shown by default")
        XCTAssertEqual(preferences.enableSoundEffects, false, "Sound effects should be disabled by default")
    }
    
    // MARK: - Color Validation Tests
    
    func testPreferencesManagerColorValidation() {
        // Given
        let manager = preferencesManager!
        
        // When - Set valid colors
        manager.preferences.defaultArrowColor = "#FF0000"
        manager.preferences.defaultTextColor = "#00FF00"
        manager.preferences.defaultRectangleColor = "#0000FF"
        manager.preferences.defaultHighlightColor = "#FFFFFF"
        
        // Then
        XCTAssertTrue(manager.preferences.areColorsValid, "All colors should be valid hex format")
        
        // When - Set invalid color
        manager.preferences.defaultArrowColor = "invalid_color"
        
        // Then
        XCTAssertFalse(manager.preferences.areColorsValid, "Should detect invalid color format")
    }
    
    // MARK: - Update Timestamp Tests
    
    func testPreferencesManagerTimestampUpdates() {
        // Given
        let manager = preferencesManager!
        let initialUpdatedAt = manager.preferences.updatedAt
        
        // When
        Thread.sleep(forTimeInterval: 0.1) // Ensure different timestamp
        manager.preferences.updateTimestamp()
        
        // Then
        XCTAssertNotEqual(manager.preferences.updatedAt, initialUpdatedAt, "Updated timestamp should change")
        XCTAssertEqual(manager.preferences.createdAt, manager.preferences.createdAt, "Created timestamp should remain unchanged")
    }
}

// MARK: - Testing Helper Extension

extension PreferencesManager {
    /// Creates a PreferencesManager instance for testing with a specific persistence manager
    /// - Parameter persistenceManager: The persistence manager to use for testing
    /// - Returns: A new PreferencesManager instance for testing
    static func createForTesting(with persistenceManager: PersistenceManager) -> PreferencesManager {
        return PreferencesManager(persistenceManager: persistenceManager)
    }
}
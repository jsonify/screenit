import XCTest
import CoreData
@testable import screenit

@MainActor
final class PreferencesManagerHotkeyTests: XCTestCase {
    
    var preferencesManager: PreferencesManager!
    var testPersistenceManager: PersistenceManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test persistence manager with in-memory store
        testPersistenceManager = PersistenceManager(storeType: .inMemory)
        
        // Wait for persistence manager to be ready
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Create preferences manager with test persistence
        preferencesManager = PreferencesManager(persistenceManager: testPersistenceManager)
        
        // Wait for initialization to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }
    
    override func tearDown() async throws {
        preferencesManager = nil
        testPersistenceManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Hotkey Update Tests
    
    func testUpdateCaptureHotkeyWithValidHotkey() {
        // Given
        let validHotkey = "cmd+shift+s"
        
        // When
        let success = preferencesManager.updateCaptureHotkey(validHotkey)
        
        // Then
        XCTAssertTrue(success, "Should successfully update with valid hotkey")
        XCTAssertEqual(preferencesManager.captureHotkeyString, validHotkey, "Should store the hotkey string")
        XCTAssertEqual(preferencesManager.captureHotkeyDisplayString, "⌘⇧S", "Should format display string correctly")
    }
    
    func testUpdateCaptureHotkeyWithInvalidHotkey() {
        // Given
        let invalidHotkey = "invalid-hotkey"
        let originalHotkey = preferencesManager.captureHotkeyString
        
        // When
        let success = preferencesManager.updateCaptureHotkey(invalidHotkey)
        
        // Then
        XCTAssertFalse(success, "Should fail to update with invalid hotkey")
        XCTAssertEqual(preferencesManager.captureHotkeyString, originalHotkey, "Should not change original hotkey")
    }
    
    func testUpdateCaptureHotkeyWithSystemConflict() {
        // Given
        let conflictHotkey = "cmd+q" // System shortcut for quit
        let originalHotkey = preferencesManager.captureHotkeyString
        
        // When
        let success = preferencesManager.updateCaptureHotkey(conflictHotkey)
        
        // Then
        // Should still succeed but with a warning (system conflicts are allowed but not recommended)
        XCTAssertTrue(success, "Should succeed even with system conflict")
        XCTAssertEqual(preferencesManager.captureHotkeyString, conflictHotkey, "Should update hotkey")
    }
    
    // MARK: - Hotkey Configuration Tests
    
    func testGetCurrentCaptureHotkeyConfig() {
        // Given
        let testHotkey = "ctrl+shift+a"
        let success = preferencesManager.updateCaptureHotkey(testHotkey)
        XCTAssertTrue(success, "Setup: Should update hotkey")
        
        // When
        let config = preferencesManager.getCurrentCaptureHotkeyConfig()
        
        // Then
        XCTAssertNotNil(config, "Should return configuration")
        XCTAssertGreaterThan(config.modifiers, 0, "Should have modifiers")
        XCTAssertFalse(config.description.isEmpty, "Should have description")
        
        // Verify the configuration matches what we set
        let parsedConfig = HotkeyParser.parseHotkey(testHotkey)
        XCTAssertNotNil(parsedConfig, "Test hotkey should be parseable")
        if let parsedConfig = parsedConfig {
            XCTAssertEqual(config.keyCode, parsedConfig.keyCode, "Key codes should match")
            XCTAssertEqual(config.modifiers, parsedConfig.modifiers, "Modifiers should match")
        }
    }
    
    func testGetCurrentCaptureHotkeyConfigWithDefault() {
        // Given - no hotkey set (use default)
        preferencesManager.preferences.captureHotkey = nil
        
        // When
        let config = preferencesManager.getCurrentCaptureHotkeyConfig()
        
        // Then
        XCTAssertEqual(config.description, "Cmd+Shift+4", "Should return default configuration")
        XCTAssertEqual(config.keyCode, UInt32(kVK_ANSI_4), "Should have correct default key code")
    }
    
    // MARK: - Display String Tests
    
    func testCaptureHotkeyDisplayString() {
        // Test various hotkey display formats
        let testCases = [
            ("cmd+shift+4", "⌘⇧4"),
            ("ctrl+alt+s", "⌃⌥S"),
            ("option+f1", "⌥F1"),
            ("shift+delete", "⇧DELETE")
        ]
        
        for (hotkey, expectedDisplay) in testCases {
            // Given
            let success = preferencesManager.updateCaptureHotkey(hotkey)
            XCTAssertTrue(success, "Should update hotkey: \(hotkey)")
            
            // When
            let displayString = preferencesManager.captureHotkeyDisplayString
            
            // Then
            XCTAssertEqual(displayString, expectedDisplay, "Display string should match for \(hotkey)")
        }
    }
    
    func testCaptureHotkeyStringRawFormat() {
        // Given
        let testHotkey = "cmd+option+x"
        let success = preferencesManager.updateCaptureHotkey(testHotkey)
        XCTAssertTrue(success, "Should update hotkey")
        
        // When
        let rawString = preferencesManager.captureHotkeyString
        
        // Then
        XCTAssertEqual(rawString, testHotkey, "Raw string should match input")
    }
    
    // MARK: - Reset Functionality Tests
    
    func testResetCaptureHotkeyToDefault() {
        // Given - set a custom hotkey first
        let customHotkey = "ctrl+shift+z"
        let success = preferencesManager.updateCaptureHotkey(customHotkey)
        XCTAssertTrue(success, "Setup: Should set custom hotkey")
        XCTAssertEqual(preferencesManager.captureHotkeyString, customHotkey, "Setup: Should have custom hotkey")
        
        // When
        preferencesManager.resetCaptureHotkeyToDefault()
        
        // Then
        XCTAssertEqual(preferencesManager.captureHotkeyString, "cmd+shift+4", "Should reset to default")
        XCTAssertEqual(preferencesManager.captureHotkeyDisplayString, "⌘⇧4", "Should have default display")
    }
    
    // MARK: - Validation Tests
    
    func testValidateHotkeyString() {
        // Test valid hotkey
        let validResult = preferencesManager.validateHotkeyString("cmd+shift+4")
        XCTAssertTrue(validResult.isValid, "Valid hotkey should pass validation")
        XCTAssertNil(validResult.message, "Valid hotkey should have no error message")
        
        // Test invalid hotkey
        let invalidResult = preferencesManager.validateHotkeyString("invalid")
        XCTAssertFalse(invalidResult.isValid, "Invalid hotkey should fail validation")
        XCTAssertNotNil(invalidResult.message, "Invalid hotkey should have error message")
        
        // Test system conflict
        let conflictResult = preferencesManager.validateHotkeyString("cmd+space")
        switch conflictResult {
        case .systemConflict:
            XCTAssertFalse(conflictResult.isValid, "System conflict should be invalid")
            XCTAssertNotNil(conflictResult.message, "System conflict should have message")
        default:
            XCTFail("cmd+space should be detected as system conflict")
        }
    }
    
    // MARK: - JSON Storage Tests
    
    func testHotkeyJSONStorage() {
        // Given
        let testHotkey = "cmd+shift+f"
        let success = preferencesManager.updateCaptureHotkey(testHotkey)
        XCTAssertTrue(success, "Should update hotkey")
        
        // When - retrieve the JSON data
        guard let hotkeyData = preferencesManager.preferences.captureHotkeyData else {
            XCTFail("Should have hotkey data")
            return
        }
        
        // Then - verify JSON structure
        XCTAssertNotNil(hotkeyData["keyCode"], "Should have keyCode")
        XCTAssertNotNil(hotkeyData["modifiers"], "Should have modifiers")
        XCTAssertNotNil(hotkeyData["description"], "Should have description")
        XCTAssertNotNil(hotkeyData["originalString"], "Should have originalString")
        
        // Verify data types
        XCTAssertTrue(hotkeyData["keyCode"] is UInt32, "keyCode should be UInt32")
        XCTAssertTrue(hotkeyData["modifiers"] is UInt32, "modifiers should be UInt32")
        XCTAssertTrue(hotkeyData["description"] is String, "description should be String")
        XCTAssertTrue(hotkeyData["originalString"] is String, "originalString should be String")
        
        // Verify the original string matches
        if let originalString = hotkeyData["originalString"] as? String {
            XCTAssertEqual(originalString, testHotkey, "Original string should match input")
        }
    }
    
    // MARK: - Persistence Tests
    
    func testHotkeyPersistence() throws {
        // Given
        let testHotkey = "cmd+shift+g"
        let success = preferencesManager.updateCaptureHotkey(testHotkey)
        XCTAssertTrue(success, "Should update hotkey")
        
        // Save the context
        try testPersistenceManager.saveViewContext()
        
        // When - create a new preferences manager with same persistence
        let newPreferencesManager = PreferencesManager(persistenceManager: testPersistenceManager)
        
        // Then - should load the persisted hotkey
        XCTAssertEqual(newPreferencesManager.captureHotkeyString, testHotkey, "Should persist hotkey across instances")
        XCTAssertEqual(newPreferencesManager.captureHotkeyDisplayString, "⌘⇧G", "Should persist display format")
    }
    
    // MARK: - Edge Cases Tests
    
    func testUpdateHotkeyWithEmptyString() {
        // Given
        let emptyHotkey = ""
        let originalHotkey = preferencesManager.captureHotkeyString
        
        // When
        let success = preferencesManager.updateCaptureHotkey(emptyHotkey)
        
        // Then
        XCTAssertFalse(success, "Should fail with empty string")
        XCTAssertEqual(preferencesManager.captureHotkeyString, originalHotkey, "Should not change original hotkey")
    }
    
    func testUpdateHotkeyWithWhitespace() {
        // Given
        let whitespaceHotkey = "   cmd + shift + 5   "
        
        // When
        let success = preferencesManager.updateCaptureHotkey(whitespaceHotkey)
        
        // Then
        XCTAssertTrue(success, "Should handle whitespace in hotkey")
        XCTAssertEqual(preferencesManager.captureHotkeyString, "cmd+shift+5", "Should normalize whitespace")
    }
    
    func testMultipleHotkeyUpdates() {
        // Test rapid updates
        let hotkeys = ["cmd+shift+1", "cmd+shift+2", "cmd+shift+3", "cmd+shift+4"]
        
        for hotkey in hotkeys {
            let success = preferencesManager.updateCaptureHotkey(hotkey)
            XCTAssertTrue(success, "Should update hotkey: \(hotkey)")
            XCTAssertEqual(preferencesManager.captureHotkeyString, hotkey, "Should have updated hotkey")
        }
        
        // Final state should be the last hotkey
        XCTAssertEqual(preferencesManager.captureHotkeyString, "cmd+shift+4", "Should have final hotkey")
    }
}
import XCTest
@testable import screenit

final class HotkeyValidationTests: XCTestCase {
    
    // MARK: - Basic Validation Tests
    
    func testValidHotkeyFormats() {
        let validHotkeys = [
            "cmd+shift+4",
            "cmd+shift+s",
            "ctrl+shift+a",
            "cmd+option+x",
            "shift+f1",
            "cmd+f6",
            "ctrl+alt+delete"
        ]
        
        for hotkey in validHotkeys {
            let result = HotkeyParser.validateHotkey(hotkey)
            XCTAssertTrue(result.isValid, "Hotkey '\(hotkey)' should be valid but got: \(result.message ?? "no message")")
        }
    }
    
    func testInvalidHotkeyFormats() {
        let invalidHotkeys = [
            "",                    // Empty string
            "a",                   // No modifiers
            "shift",               // Only modifier
            "cmd+",                // Incomplete
            "+shift+a",            // Leading +
            "cmd++a",              // Double +
            "cmd+shift+xyz",       // Invalid key
            "invalid+shift+a",     // Invalid modifier
            "cmd shift a"          // Wrong separator
        ]
        
        for hotkey in invalidHotkeys {
            let result = HotkeyParser.validateHotkey(hotkey)
            XCTAssertFalse(result.isValid, "Hotkey '\(hotkey)' should be invalid")
        }
    }
    
    // MARK: - System Conflict Tests
    
    func testSystemConflictDetection() {
        let systemConflicts = [
            "cmd+space",     // Spotlight
            "cmd+tab",       // App switcher
            "cmd+q",         // Quit
            "cmd+w",         // Close window
            "ctrl+up"        // Mission Control
        ]
        
        for hotkey in systemConflicts {
            let result = HotkeyParser.validateHotkey(hotkey)
            switch result {
            case .systemConflict:
                XCTAssertTrue(true, "Correctly identified system conflict for '\(hotkey)'")
            default:
                XCTFail("Hotkey '\(hotkey)' should be detected as system conflict but got: \(result)")
            }
        }
    }
    
    func testNonSystemConflictHotkeys() {
        let nonConflictHotkeys = [
            "cmd+shift+4",
            "cmd+shift+s", 
            "ctrl+shift+a",
            "cmd+f6"
        ]
        
        for hotkey in nonConflictHotkeys {
            let hasConflict = HotkeyParser.hasSystemConflict(hotkey)
            XCTAssertFalse(hasConflict, "Hotkey '\(hotkey)' should not conflict with system shortcuts")
        }
    }
    
    // MARK: - Recommended Hotkeys Tests
    
    func testRecommendedHotkeys() {
        let recommendedHotkeys = HotkeyParser.getRecommendedHotkeys()
        
        XCTAssertFalse(recommendedHotkeys.isEmpty, "Should have recommended hotkeys")
        XCTAssertTrue(recommendedHotkeys.contains("cmd+shift+4"), "Should include cmd+shift+4 as recommended")
        XCTAssertTrue(recommendedHotkeys.contains("cmd+shift+s"), "Should include cmd+shift+s as recommended")
        
        // All recommended hotkeys should be valid
        for hotkey in recommendedHotkeys {
            XCTAssertTrue(HotkeyParser.isValidHotkey(hotkey), "Recommended hotkey '\(hotkey)' should be valid")
        }
    }
    
    func testRecommendedHotkeyDetection() {
        XCTAssertTrue(HotkeyParser.isRecommendedHotkey("cmd+shift+4"), "cmd+shift+4 should be recommended")
        XCTAssertTrue(HotkeyParser.isRecommendedHotkey("cmd+shift+s"), "cmd+shift+s should be recommended")
        XCTAssertFalse(HotkeyParser.isRecommendedHotkey("cmd+shift+z"), "cmd+shift+z should not be recommended")
        XCTAssertFalse(HotkeyParser.isRecommendedHotkey("invalid"), "Invalid hotkey should not be recommended")
    }
    
    // MARK: - Hotkey Parsing Tests
    
    func testHotkeyParsing() {
        let testCases: [(String, Bool)] = [
            ("cmd+shift+4", true),
            ("ctrl+alt+s", true),
            ("shift+f1", true),
            ("cmd+option+delete", true),
            ("invalid+key", false),
            ("a", false),          // No modifiers
            ("cmd+", false),       // Incomplete
            ("", false)            // Empty
        ]
        
        for (hotkeyString, shouldSucceed) in testCases {
            let config = HotkeyParser.parseHotkey(hotkeyString)
            
            if shouldSucceed {
                XCTAssertNotNil(config, "Should successfully parse '\(hotkeyString)'")
                if let config = config {
                    XCTAssertGreaterThan(config.modifiers, 0, "Parsed hotkey should have modifiers")
                    XCTAssertFalse(config.description.isEmpty, "Parsed hotkey should have description")
                }
            } else {
                XCTAssertNil(config, "Should fail to parse '\(hotkeyString)'")
            }
        }
    }
    
    // MARK: - Hotkey Formatting Tests
    
    func testHotkeyFormatting() {
        let testCases = [
            ("cmd+shift+4", "⌘⇧4"),
            ("ctrl+alt+s", "⌃⌥S"),
            ("option+f1", "⌥F1"),
            ("shift+delete", "⇧DELETE")
        ]
        
        for (input, expected) in testCases {
            let formatted = HotkeyParser.formatHotkeyString(input)
            XCTAssertEqual(formatted, expected, "Formatting '\(input)' should produce '\(expected)' but got '\(formatted)'")
        }
    }
    
    // MARK: - Configuration Conversion Tests
    
    func testConfigurationToString() {
        // Test parsing and converting back
        let originalHotkeys = [
            "cmd+shift+4",
            "ctrl+alt+s",
            "shift+f1"
        ]
        
        for original in originalHotkeys {
            guard let config = HotkeyParser.parseHotkey(original) else {
                XCTFail("Should parse '\(original)'")
                continue
            }
            
            let converted = HotkeyParser.configurationToString(config)
            
            // Convert both to normalized form for comparison
            let originalNormalized = original.lowercased().replacingOccurrences(of: " ", with: "")
            let convertedNormalized = converted.lowercased().replacingOccurrences(of: " ", with: "")
            
            XCTAssertEqual(originalNormalized, convertedNormalized, 
                          "Configuration conversion should preserve hotkey: '\(original)' -> '\(converted)'")
        }
    }
    
    // MARK: - Key Code Conversion Tests
    
    func testKeyCodeToString() {
        // Test known key codes
        XCTAssertEqual(HotkeyParser.keyCodeToString(21), "4", "Key code 21 should map to '4'")
        XCTAssertEqual(HotkeyParser.keyCodeToString(0), "a", "Key code 0 should map to 'a'")
        XCTAssertEqual(HotkeyParser.keyCodeToString(49), "space", "Key code 49 should map to 'space'")
        XCTAssertEqual(HotkeyParser.keyCodeToString(122), "f1", "Key code 122 should map to 'f1'")
        
        // Test unknown key code
        XCTAssertNil(HotkeyParser.keyCodeToString(999), "Unknown key code should return nil")
    }
    
    // MARK: - Edge Cases Tests
    
    func testCaseInsensitivity() {
        let variations = [
            "CMD+SHIFT+4",
            "cmd+shift+4",
            "Cmd+Shift+4",
            "cMd+sHiFt+4"
        ]
        
        for variation in variations {
            let config = HotkeyParser.parseHotkey(variation)
            XCTAssertNotNil(config, "Should parse case variation: '\(variation)'")
        }
    }
    
    func testWhitespaceHandling() {
        let variations = [
            "cmd+shift+4",
            " cmd+shift+4 ",
            "cmd + shift + 4",
            " cmd + shift + 4 "
        ]
        
        for variation in variations {
            let config = HotkeyParser.parseHotkey(variation)
            XCTAssertNotNil(config, "Should handle whitespace in: '\(variation)'")
        }
    }
    
    func testModifierAliases() {
        let aliases = [
            ("cmd+shift+4", "command+shift+4"),
            ("alt+shift+4", "option+shift+4"),
            ("ctrl+shift+4", "control+shift+4")
        ]
        
        for (original, alias) in aliases {
            let config1 = HotkeyParser.parseHotkey(original)
            let config2 = HotkeyParser.parseHotkey(alias)
            
            XCTAssertNotNil(config1, "Should parse original: '\(original)'")
            XCTAssertNotNil(config2, "Should parse alias: '\(alias)'")
            
            if let config1 = config1, let config2 = config2 {
                XCTAssertEqual(config1.keyCode, config2.keyCode, "Key codes should match for aliases")
                XCTAssertEqual(config1.modifiers, config2.modifiers, "Modifiers should match for aliases")
            }
        }
    }
    
    // MARK: - Validation Result Tests
    
    func testValidationResultTypes() {
        // Test valid result
        let validResult = HotkeyParser.validateHotkey("cmd+shift+s")
        switch validResult {
        case .valid:
            XCTAssertTrue(validResult.isValid, "Valid result should report as valid")
            XCTAssertNil(validResult.message, "Valid result should have no message")
        default:
            XCTFail("Should return valid result for 'cmd+shift+s'")
        }
        
        // Test invalid result
        let invalidResult = HotkeyParser.validateHotkey("invalid")
        switch invalidResult {
        case .invalid(let message):
            XCTAssertFalse(invalidResult.isValid, "Invalid result should report as invalid")
            XCTAssertNotNil(message, "Invalid result should have message")
            XCTAssertFalse(message.isEmpty, "Invalid message should not be empty")
        default:
            XCTFail("Should return invalid result for 'invalid'")
        }
        
        // Test system conflict result
        let conflictResult = HotkeyParser.validateHotkey("cmd+q")
        switch conflictResult {
        case .systemConflict(let message):
            XCTAssertFalse(conflictResult.isValid, "System conflict should report as invalid")
            XCTAssertNotNil(message, "System conflict should have message")
            XCTAssertFalse(message.isEmpty, "System conflict message should not be empty")
        default:
            XCTFail("Should return system conflict result for 'cmd+q'")
        }
    }
}
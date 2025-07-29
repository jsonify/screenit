import Foundation
import Carbon

// MARK: - Hotkey Parsing and Configuration

struct HotkeyParser {
    
    // MARK: - Key Code Mapping
    
    private static let keyCodeMap: [String: UInt32] = [
        // Numbers
        "0": UInt32(kVK_ANSI_0),
        "1": UInt32(kVK_ANSI_1),
        "2": UInt32(kVK_ANSI_2),
        "3": UInt32(kVK_ANSI_3),
        "4": UInt32(kVK_ANSI_4),
        "5": UInt32(kVK_ANSI_5),
        "6": UInt32(kVK_ANSI_6),
        "7": UInt32(kVK_ANSI_7),
        "8": UInt32(kVK_ANSI_8),
        "9": UInt32(kVK_ANSI_9),
        
        // Letters
        "a": UInt32(kVK_ANSI_A),
        "b": UInt32(kVK_ANSI_B),
        "c": UInt32(kVK_ANSI_C),
        "d": UInt32(kVK_ANSI_D),
        "e": UInt32(kVK_ANSI_E),
        "f": UInt32(kVK_ANSI_F),
        "g": UInt32(kVK_ANSI_G),
        "h": UInt32(kVK_ANSI_H),
        "i": UInt32(kVK_ANSI_I),
        "j": UInt32(kVK_ANSI_J),
        "k": UInt32(kVK_ANSI_K),
        "l": UInt32(kVK_ANSI_L),
        "m": UInt32(kVK_ANSI_M),
        "n": UInt32(kVK_ANSI_N),
        "o": UInt32(kVK_ANSI_O),
        "p": UInt32(kVK_ANSI_P),
        "q": UInt32(kVK_ANSI_Q),
        "r": UInt32(kVK_ANSI_R),
        "s": UInt32(kVK_ANSI_S),
        "t": UInt32(kVK_ANSI_T),
        "u": UInt32(kVK_ANSI_U),
        "v": UInt32(kVK_ANSI_V),
        "w": UInt32(kVK_ANSI_W),
        "x": UInt32(kVK_ANSI_X),
        "y": UInt32(kVK_ANSI_Y),
        "z": UInt32(kVK_ANSI_Z),
        
        // Function keys
        "f1": UInt32(kVK_F1),
        "f2": UInt32(kVK_F2),
        "f3": UInt32(kVK_F3),
        "f4": UInt32(kVK_F4),
        "f5": UInt32(kVK_F5),
        "f6": UInt32(kVK_F6),
        "f7": UInt32(kVK_F7),
        "f8": UInt32(kVK_F8),
        "f9": UInt32(kVK_F9),
        "f10": UInt32(kVK_F10),
        "f11": UInt32(kVK_F11),
        "f12": UInt32(kVK_F12),
        
        // Special keys
        "space": UInt32(kVK_Space),
        "return": UInt32(kVK_Return),
        "enter": UInt32(kVK_Return),
        "tab": UInt32(kVK_Tab),
        "escape": UInt32(kVK_Escape),
        "esc": UInt32(kVK_Escape),
        "delete": UInt32(kVK_Delete),
        "backspace": UInt32(kVK_Delete),
        
        // Arrow keys
        "left": UInt32(kVK_LeftArrow),
        "right": UInt32(kVK_RightArrow),
        "up": UInt32(kVK_UpArrow),
        "down": UInt32(kVK_DownArrow),
        
        // Symbols
        "-": UInt32(kVK_ANSI_Minus),
        "=": UInt32(kVK_ANSI_Equal),
        "[": UInt32(kVK_ANSI_LeftBracket),
        "]": UInt32(kVK_ANSI_RightBracket),
        "\\": UInt32(kVK_ANSI_Backslash),
        ";": UInt32(kVK_ANSI_Semicolon),
        "'": UInt32(kVK_ANSI_Quote),
        ",": UInt32(kVK_ANSI_Comma),
        ".": UInt32(kVK_ANSI_Period),
        "/": UInt32(kVK_ANSI_Slash),
        "`": UInt32(kVK_ANSI_Grave)
    ]
    
    // MARK: - Modifier Mapping
    
    private static let modifierMap: [String: UInt32] = [
        "cmd": UInt32(cmdKey),
        "command": UInt32(cmdKey),
        "shift": UInt32(shiftKey),
        "option": UInt32(optionKey),
        "alt": UInt32(optionKey),
        "ctrl": UInt32(controlKey),
        "control": UInt32(controlKey)
    ]
    
    // MARK: - Validation Rules
    
    private static let validCombinations: Set<String> = [
        // Common screenshot combinations
        "cmd+shift+3", "cmd+shift+4", "cmd+shift+5",
        // Alternative combinations
        "cmd+shift+s", "cmd+shift+c", "cmd+shift+x",
        "ctrl+shift+4", "ctrl+shift+s",
        // Function key combinations
        "cmd+f1", "cmd+f2", "cmd+f3", "cmd+f4", "cmd+f5", "cmd+f6",
        "shift+f1", "shift+f2", "shift+f3", "shift+f4", "shift+f5", "shift+f6",
        // Letter combinations
        "cmd+shift+a", "cmd+shift+d", "cmd+shift+g", "cmd+shift+p", "cmd+shift+w"
    ]
    
    // MARK: - Public Interface
    
    /// Parses a hotkey string into a HotkeyConfiguration
    static func parseHotkey(_ hotkeyString: String) -> GlobalHotkeyManager.HotkeyConfiguration? {
        let normalizedString = hotkeyString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !normalizedString.isEmpty else { return nil }
        
        // Split by + character
        let components = normalizedString.split(separator: "+").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        guard components.count >= 2 else { return nil }
        
        // Last component should be the key
        let keyString = components.last!
        let modifierStrings = Array(components.dropLast())
        
        // Parse key code
        guard let keyCode = keyCodeMap[keyString] else {
            print("❌ [DEBUG] Unknown key: \(keyString)")
            return nil
        }
        
        // Parse modifiers
        var modifiers: UInt32 = 0
        for modifierString in modifierStrings {
            guard let modifier = modifierMap[modifierString] else {
                print("❌ [DEBUG] Unknown modifier: \(modifierString)")
                return nil
            }
            modifiers |= modifier
        }
        
        // Ensure at least one modifier is present (required for global hotkeys)
        guard modifiers != 0 else {
            print("❌ [DEBUG] Hotkey must have at least one modifier")
            return nil
        }
        
        let configuration = GlobalHotkeyManager.HotkeyConfiguration(
            keyCode: keyCode,
            modifiers: modifiers,
            description: formatHotkeyString(normalizedString)
        )
        
        print("✅ [DEBUG] Parsed hotkey: \(configuration.description)")
        return configuration
    }
    
    /// Validates if a hotkey string is valid
    static func isValidHotkey(_ hotkeyString: String) -> Bool {
        return parseHotkey(hotkeyString) != nil
    }
    
    /// Checks if a hotkey is a recommended combination
    static func isRecommendedHotkey(_ hotkeyString: String) -> Bool {
        let normalized = hotkeyString.lowercased().replacingOccurrences(of: " ", with: "")
        return validCombinations.contains(normalized)
    }
    
    /// Gets a list of recommended hotkey combinations
    static func getRecommendedHotkeys() -> [String] {
        return Array(validCombinations).sorted()
    }
    
    /// Formats a hotkey string for display with proper symbols
    static func formatHotkeyString(_ hotkeyString: String) -> String {
        return hotkeyString
            .replacingOccurrences(of: "cmd", with: "⌘")
            .replacingOccurrences(of: "command", with: "⌘")
            .replacingOccurrences(of: "shift", with: "⇧")
            .replacingOccurrences(of: "option", with: "⌥")
            .replacingOccurrences(of: "alt", with: "⌥")
            .replacingOccurrences(of: "ctrl", with: "⌃")
            .replacingOccurrences(of: "control", with: "⌃")
            .replacingOccurrences(of: "+", with: "")
            .uppercased()
    }
    
    /// Converts a HotkeyConfiguration back to a string
    static func configurationToString(_ config: GlobalHotkeyManager.HotkeyConfiguration) -> String {
        var components: [String] = []
        
        // Add modifiers
        if config.modifiers & UInt32(cmdKey) != 0 {
            components.append("cmd")
        }
        if config.modifiers & UInt32(shiftKey) != 0 {
            components.append("shift")
        }
        if config.modifiers & UInt32(optionKey) != 0 {
            components.append("option")
        }
        if config.modifiers & UInt32(controlKey) != 0 {
            components.append("ctrl")
        }
        
        // Find the key
        for (key, code) in keyCodeMap {
            if code == config.keyCode {
                components.append(key)
                break
            }
        }
        
        return components.joined(separator: "+")
    }
    
    /// Checks if a hotkey conflicts with system shortcuts
    static func hasSystemConflict(_ hotkeyString: String) -> Bool {
        let systemConflicts = [
            "cmd+space",     // Spotlight
            "cmd+tab",       // App switcher
            "cmd+`",         // Window switcher
            "cmd+shift+tab", // Reverse app switcher
            "cmd+option+esc", // Force quit
            "cmd+q",         // Quit
            "cmd+w",         // Close window
            "cmd+m",         // Minimize
            "cmd+h",         // Hide
            "cmd+shift+q",   // Logout
            "ctrl+up",       // Mission Control
            "ctrl+down",     // Application windows
            "ctrl+left",     // Move left space
            "ctrl+right"     // Move right space
        ]
        
        let normalized = hotkeyString.lowercased().replacingOccurrences(of: " ", with: "")
        return systemConflicts.contains(normalized)
    }
}

// MARK: - Hotkey Validation Results

enum HotkeyValidationResult {
    case valid
    case invalid(String)
    case systemConflict(String)
    case notRecommended(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        default:
            return false
        }
    }
    
    var message: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message), .systemConflict(let message), .notRecommended(let message):
            return message
        }
    }
}

// MARK: - Extended Validation

extension HotkeyParser {
    
    /// Performs comprehensive validation of a hotkey string
    static func validateHotkey(_ hotkeyString: String) -> HotkeyValidationResult {
        // Basic validation
        guard isValidHotkey(hotkeyString) else {
            return .invalid("Invalid hotkey format. Use format like 'cmd+shift+4'")
        }
        
        // System conflict check
        if hasSystemConflict(hotkeyString) {
            return .systemConflict("This hotkey conflicts with a system shortcut")
        }
        
        // Recommendation check
        if !isRecommendedHotkey(hotkeyString) {
            return .notRecommended("Consider using a recommended hotkey combination for better compatibility")
        }
        
        return .valid
    }
}
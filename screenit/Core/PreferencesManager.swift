import Foundation
import SwiftUI
import Combine

// MARK: - Preferences Data Model

struct ScreenitPreferences: Codable {
    // Capture settings
    var captureHotkey: String = "cmd+shift+4"
    var saveLocation: String = "desktop" // "desktop", "downloads", "custom"
    var customSaveLocation: String = ""
    var showPreviewWindow: Bool = true
    var previewDuration: Double = 6.0
    
    // Annotation settings
    var defaultAnnotationColor: String = "#FF0000" // Red
    var defaultArrowThickness: Double = 3.0
    var defaultTextSize: Double = 16.0
    var showAnnotationToolbar: Bool = true
    
    // History settings
    var historyRetentionLimit: Int = 10
    var enableHistoryThumbnails: Bool = true
    var autoSaveToHistory: Bool = true
    
    // UI settings
    var showMenuBarIcon: Bool = true
    var launchAtLogin: Bool = false
    var enableSounds: Bool = true
    var enableNotifications: Bool = true
    
    // Performance settings
    var enableHighDPICapture: Bool = true
    var compressionQuality: Double = 0.9
    var maxImageSize: Int = 4000 // Max width/height in pixels
    
    init() {}
}

// MARK: - Preferences Manager

@MainActor
class PreferencesManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = PreferencesManager()
    
    // MARK: - Published Properties
    
    @Published var preferences = ScreenitPreferences()
    @Published var isPreferencesWindowOpen = false
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "ScreenitPreferences"
    private var preferencesWindow: NSWindow?
    
    // MARK: - Initialization
    
    private init() {
        loadPreferences()
        
        // Observe changes and auto-save
        $preferences
            .dropFirst() // Skip initial load
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] newPreferences in
                self?.savePreferences()
                
                // Notify about hotkey changes
                NotificationCenter.default.post(
                    name: NSNotification.Name("HotkeyPreferenceChanged"),
                    object: newPreferences.captureHotkey
                )
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Persistence
    
    private func loadPreferences() {
        print("📚 [DEBUG] Loading preferences from UserDefaults")
        
        guard let data = userDefaults.data(forKey: preferencesKey) else {
            print("📚 [DEBUG] No saved preferences found, using defaults")
            preferences = ScreenitPreferences()
            return
        }
        
        do {
            preferences = try JSONDecoder().decode(ScreenitPreferences.self, from: data)
            print("✅ [DEBUG] Preferences loaded successfully")
        } catch {
            print("❌ [DEBUG] Failed to decode preferences: \(error)")
            preferences = ScreenitPreferences()
        }
    }
    
    private func savePreferences() {
        print("💾 [DEBUG] Saving preferences to UserDefaults")
        
        do {
            let data = try JSONEncoder().encode(preferences)
            userDefaults.set(data, forKey: preferencesKey)
            print("✅ [DEBUG] Preferences saved successfully")
        } catch {
            print("❌ [DEBUG] Failed to encode preferences: \(error)")
        }
    }
    
    // MARK: - Public Interface
    
    func resetToDefaults() {
        print("🔄 [DEBUG] Resetting preferences to defaults")
        preferences = ScreenitPreferences()
    }
    
    func exportPreferences() -> Data? {
        do {
            return try JSONEncoder().encode(preferences)
        } catch {
            print("❌ [DEBUG] Failed to export preferences: \(error)")
            return nil
        }
    }
    
    func importPreferences(from data: Data) -> Bool {
        do {
            let importedPreferences = try JSONDecoder().decode(ScreenitPreferences.self, from: data)
            preferences = importedPreferences
            print("✅ [DEBUG] Preferences imported successfully")
            return true
        } catch {
            print("❌ [DEBUG] Failed to import preferences: \(error)")
            return false
        }
    }
    
    // MARK: - Save Location Helpers
    
    var effectiveSaveLocation: URL? {
        switch preferences.saveLocation {
        case "desktop":
            return try? FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        case "downloads":
            return try? FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        case "custom":
            guard !preferences.customSaveLocation.isEmpty else { return nil }
            return URL(fileURLWithPath: preferences.customSaveLocation)
        default:
            return try? FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        }
    }
    
    var saveLocationDisplayName: String {
        switch preferences.saveLocation {
        case "desktop":
            return "Desktop"
        case "downloads":
            return "Downloads"
        case "custom":
            if preferences.customSaveLocation.isEmpty {
                return "Custom (not set)"
            } else {
                return URL(fileURLWithPath: preferences.customSaveLocation).lastPathComponent
            }
        default:
            return "Desktop"
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
        
        print("✅ [DEBUG] Preferences window created and displayed")
    }
    
    func closePreferencesWindow() {
        preferencesWindow?.close()
        preferencesWindow = nil
        isPreferencesWindowOpen = false
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
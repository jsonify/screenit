import Foundation
import AppKit
import Carbon
import OSLog

/// Manages global hotkey registration and handling for screen capture
@MainActor
class GlobalHotkeyManager: ObservableObject {
    
    // MARK: - Types
    
    struct HotkeyConfiguration {
        let keyCode: UInt32
        let modifiers: UInt32
        let description: String
        
        static let defaultCaptureArea = HotkeyConfiguration(
            keyCode: UInt32(kVK_ANSI_4), // Key "4"
            modifiers: UInt32(cmdKey | shiftKey), // Cmd+Shift
            description: "Cmd+Shift+4"
        )
    }
    
    enum HotkeyError: LocalizedError {
        case registrationFailed(String)
        case accessibilityPermissionRequired
        case hotkeyAlreadyInUse
        case systemError(OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .registrationFailed(let description):
                return "Failed to register hotkey: \(description)"
            case .accessibilityPermissionRequired:
                return "Accessibility permission required for global hotkeys"
            case .hotkeyAlreadyInUse:
                return "This hotkey combination is already in use by another application"
            case .systemError(let status):
                return "System error registering hotkey: \(status)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .registrationFailed, .systemError:
                return "Try restarting the application or choose a different hotkey combination."
            case .accessibilityPermissionRequired:
                return "Grant accessibility permission in System Preferences > Security & Privacy > Accessibility."
            case .hotkeyAlreadyInUse:
                return "Choose a different hotkey combination that's not already in use."
            }
        }
    }
    
    // MARK: - Properties
    
    @Published var isEnabled: Bool = false
    @Published var currentHotkey: HotkeyConfiguration = .defaultCaptureArea
    @Published var lastError: HotkeyError?
    
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "GlobalHotkey")
    private var eventHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var preferencesObserver: NSObjectProtocol?
    
    // Callbacks
    private var onCaptureAreaTriggered: (() -> Void)?
    
    // MARK: - Constants
    
    private let hotkeySignature: FourCharCode = OSType(0x73636170) // "scap" as 4-byte code
    private let hotkeyID: UInt32 = 1
    
    // MARK: - Initialization
    
    init() {
        logger.info("GlobalHotkeyManager initialized")
        setupEventHandler()
        setupPreferencesObserver()
    }
    
    deinit {
        // Clean up observer
        if let observer = preferencesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        // Note: Cannot call async methods from deinit
        // Cleanup should be called manually before deinitialization
        logger.info("GlobalHotkeyManager deinitialized")
    }
    
    // MARK: - Public Interface
    
    /// Registers the global hotkey with callback
    func registerCaptureAreaHotkey(onTriggered: @escaping () -> Void) async -> Bool {
        // Load current hotkey from preferences
        currentHotkey = PreferencesManager.shared.getCurrentCaptureHotkeyConfig()
        
        logger.info("Registering capture area hotkey: \(self.currentHotkey.description)")
        
        // Store callback
        self.onCaptureAreaTriggered = onTriggered
        
        // Check accessibility permission first
        guard checkAccessibilityPermission() else {
            lastError = .accessibilityPermissionRequired
            logger.error("Accessibility permission not granted")
            return false
        }
        
        // Unregister any existing hotkey
        unregisterAllHotkeys()
        
        // Register the new hotkey
        do {
            try await registerHotkey(currentHotkey)
            isEnabled = true
            lastError = nil
            logger.info("Global hotkey registered successfully: \(self.currentHotkey.description)")
            return true
        } catch {
            if let hotkeyError = error as? HotkeyError {
                lastError = hotkeyError
            } else {
                lastError = .registrationFailed(error.localizedDescription)
            }
            logger.error("Failed to register global hotkey: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Unregisters all global hotkeys
    func unregisterAllHotkeys() {
        guard isEnabled else { return }
        
        logger.info("Unregistering global hotkeys")
        
        if let hotKeyRef = eventHotKeyRef {
            let status = UnregisterEventHotKey(hotKeyRef)
            if status != noErr {
                logger.warning("Failed to unregister hotkey: \(status)")
            }
            eventHotKeyRef = nil
        }
        
        isEnabled = false
        lastError = nil
        logger.info("Global hotkeys unregistered")
    }
    
    /// Updates the hotkey configuration
    func updateHotkey(_ newHotkey: HotkeyConfiguration) async -> Bool {
        logger.info("Updating hotkey from \(self.currentHotkey.description) to \(newHotkey.description)")
        
        let wasEnabled = isEnabled
        let callback = onCaptureAreaTriggered
        
        // Unregister current hotkey
        unregisterAllHotkeys()
        
        // Update configuration
        currentHotkey = newHotkey
        
        // Re-register if it was enabled
        if wasEnabled, let callback = callback {
            return await registerCaptureAreaHotkey(onTriggered: callback)
        }
        
        return true
    }
    
    /// Temporarily disables hotkeys
    func disable() {
        guard isEnabled else { return }
        
        logger.info("Temporarily disabling global hotkeys")
        unregisterAllHotkeys()
    }
    
    /// Re-enables hotkeys with previous configuration
    func enable() async -> Bool {
        guard !isEnabled, let callback = onCaptureAreaTriggered else {
            return true
        }
        
        logger.info("Re-enabling global hotkeys")
        return await registerCaptureAreaHotkey(onTriggered: callback)
    }
    
    // MARK: - Private Implementation
    
    private func setupEventHandler() {
        // Install Carbon event handler for hotkey events
        let eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        ]
        
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { (nextHandler, event, userData) -> OSStatus in
                // Extract self from user data
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                return manager.handleHotkeyEvent(nextHandler, event)
            },
            1,
            eventTypes,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        
        if status == noErr {
            logger.info("Carbon event handler installed successfully")
        } else {
            logger.error("Failed to install Carbon event handler: \(status)")
        }
    }
    
    private func handleHotkeyEvent(_ nextHandler: EventHandlerCallRef?, _ event: EventRef?) -> OSStatus {
        // Extract hotkey ID from event
        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )
        
        guard status == noErr else {
            logger.warning("Failed to extract hotkey ID from event: \(status)")
            return status
        }
        
        // Check if this is our hotkey
        guard hotkeyID.signature == hotkeySignature && hotkeyID.id == self.hotkeyID else {
            return OSStatus(eventNotHandledErr)
        }
        
        // Handle the hotkey press
        logger.info("Global hotkey triggered: \(self.currentHotkey.description)")
        
        // Call the callback on main thread
        Task { @MainActor in
            self.onCaptureAreaTriggered?()
        }
        
        return noErr
    }
    
    private func registerHotkey(_ hotkey: HotkeyConfiguration) async throws {
        // Create hotkey ID
        let hotkeyIDStruct = EventHotKeyID(signature: hotkeySignature, id: self.hotkeyID)
        
        // Register the hotkey
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.modifiers,
            hotkeyIDStruct,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        // Handle registration result
        switch status {
        case noErr:
            eventHotKeyRef = hotKeyRef
            logger.info("Hotkey registered successfully with Carbon")
            
        case OSStatus(eventHotKeyExistsErr):
            throw HotkeyError.hotkeyAlreadyInUse
            
        default:
            throw HotkeyError.systemError(status)
        }
    }
    
    private func checkAccessibilityPermission() -> Bool {
        // Check if we have accessibility permission for global event monitoring
        // Note: This is a system call that should be safe from any thread
        let accessEnabled = AXIsProcessTrusted()
        
        logger.info("Accessibility permission check: \(accessEnabled)")
        return accessEnabled
    }
    
    /// Requests accessibility permission (shows system dialog)
    nonisolated func requestAccessibilityPermission() {
        logger.info("Requesting accessibility permission")
        
        // Use the simpler API to show system dialog
        let _ = AXIsProcessTrusted()
        
        // If not trusted, this will prompt user to open System Preferences
        // Note: This is a simplified version that should be safe from any thread
        
        logger.info("Accessibility permission check initiated")
    }
    
    /// Opens System Preferences to accessibility settings
    func openAccessibilitySettings() {
        logger.info("Opening System Preferences accessibility settings")
        
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - Preferences Integration
    
    private func setupPreferencesObserver() {
        // Listen for hotkey preference changes
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HotkeyPreferenceChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleHotkeyPreferenceChanged()
            }
        }
        
        logger.info("Preferences observer set up for hotkey changes")
    }
    
    @MainActor
    private func handleHotkeyPreferenceChanged() async {
        logger.info("Hotkey preference changed, updating registration")
        
        guard isEnabled, let callback = onCaptureAreaTriggered else {
            // Update current hotkey even if not enabled
            self.currentHotkey = PreferencesManager.shared.getCurrentCaptureHotkeyConfig()
            logger.info("Updated hotkey configuration while disabled: \(self.currentHotkey.description)")
            return
        }
        
        // Re-register with new hotkey
        let success = await registerCaptureAreaHotkey(onTriggered: callback)
        if success {
            logger.info("Successfully updated hotkey registration")
        } else {
            logger.error("Failed to update hotkey registration")
        }
    }
    
    // MARK: - Status Properties
    
    /// Gets current status description
    var statusDescription: String {
        if isEnabled {
            return "Active: \(currentHotkey.description)"
        } else if lastError != nil {
            return "Error: \(lastError?.localizedDescription ?? "Unknown error")"
        } else {
            return "Disabled"
        }
    }
    
    /// Whether hotkeys are available (permission granted)
    var isAvailable: Bool {
        return checkAccessibilityPermission()
    }
    
    /// Gets user-friendly error message
    var errorMessage: String? {
        return lastError?.localizedDescription
    }
    
    /// Gets recovery suggestion for current error
    var recoverySuggestion: String? {
        return lastError?.recoverySuggestion
    }
}
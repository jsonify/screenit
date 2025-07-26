import SwiftUI
import Combine
import UniformTypeIdentifiers
import AppKit

// MARK: - Menu Positioning Types

struct MenuPositioning: CustomStringConvertible {
    let edge: NSRectEdge
    let alignment: MenuAlignment
    
    var description: String {
        return "edge: \(edgeDescription), alignment: \(alignment)"
    }
    
    private var edgeDescription: String {
        switch edge {
        case .minY: return "below"
        case .maxY: return "above"
        case .minX: return "left"
        case .maxX: return "right"
        @unknown default: return "unknown"
        }
    }
}

enum MenuAlignment {
    case leading
    case center
    case trailing
}

// MARK: - Status Item Errors

enum StatusItemError: LocalizedError {
    case creationFailed
    case buttonAccessFailed
    case iconLoadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Failed to create menu bar status item"
        case .buttonAccessFailed:
            return "Failed to access status item button"
        case .iconLoadFailed(let iconName):
            return "Failed to load icon '\(iconName)'"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .creationFailed:
            return "The system may be low on resources or the menu bar may be full. Try restarting the application."
        case .buttonAccessFailed:
            return "This may be a system issue. Try restarting the application."
        case .iconLoadFailed:
            return "The system may not support this SF Symbol. A default icon will be used instead."
        }
    }
}

@MainActor
class MenuBarManager: ObservableObject {
    // MARK: - NSStatusItem Properties
    private(set) var statusItem: NSStatusItem?
    private(set) var popover: NSPopover?
    @Published var isVisible: Bool = true
    @Published var showingPermissionAlert: Bool = false
    @Published var showingErrorAlert: Bool = false
    @Published var showingSuccessNotification: Bool = false
    @Published var isCapturing: Bool = false
    @Published var lastErrorMessage: String = ""
    @Published var lastSuccessMessage: String = ""
    @Published var performanceStatus: String = ""
    @Published var statusItemError: String = ""
    
    // MARK: - Static Properties
    private static var hasLoggedSecurityContext = false
    
    // MARK: - Dependencies
    private let permissionManager = ScreenCapturePermissionManager()
    private let captureEngine = CaptureEngine.shared
    private let overlayManager = CaptureOverlayManager()
    private let hotkeyManager = GlobalHotkeyManager()
    
    init() {
        // Defer heavy initialization to prevent circular dependencies during app launch
        Task { @MainActor in
            // Small delay to ensure SwiftUI initialization is complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            setupMenuBar()
            setupNotifications()
            setupTerminationHandling()
            setupGlobalHotkeys()
        }
    }
    
    deinit {
        print("MenuBarManager deinitializing - performing final cleanup")
        
        // Clean up notification observers
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        
        print("MenuBarManager deinitialization complete")
    }
    
    // MARK: - Menu Bar Setup
    
    private func setupMenuBar() {
        do {
            try setupStatusItem()
            setupPopover()
            setupSystemAppearanceObserver()
        } catch {
            handleStatusItemError(error)
        }
    }
    
    private func setupStatusItem() throws {
        // Create status item with error handling
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        self.statusItem = statusItem
        
        // Configure status button with SF Symbols icon
        guard let button = statusItem.button else {
            throw StatusItemError.buttonAccessFailed
        }
        
        // Use SF Symbols icon with fallback
        let iconName = "camera.viewfinder"
        guard let iconImage = NSImage(systemSymbolName: iconName, accessibilityDescription: "screenit") else {
            throw StatusItemError.iconLoadFailed(iconName)
        }
        
        // Configure button properties
        button.image = iconImage
        button.image?.isTemplate = true  // Enable automatic dark/light mode adaptation
        button.toolTip = "screenit - Screenshot tool"
        button.target = self
        button.action = #selector(statusItemClicked)
        
        // Set up accessibility
        if let cell = button.cell {
            cell.setAccessibilityTitle("screenit menu bar button")
        }
        
        print("Status item created successfully with SF Symbol: \(iconName)")
    }
    
    private func setupSystemAppearanceObserver() {
        // Observe system appearance changes for better integration
        // Note: Using a general notification for appearance changes
        // Template images automatically adapt to system appearance
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppearanceChange()
            }
        }
    }
    
    private func handleAppearanceChange() {
        // Template images automatically adapt, but we can perform additional customizations here if needed
        guard let statusItem = statusItem, let button = statusItem.button else { return }
        
        // Ensure template mode is maintained across appearance changes
        button.image?.isTemplate = true
        
        print("System appearance changed - status item adapted")
    }
    
    private func handleStatusItemError(_ error: Error) {
        let errorMessage: String
        
        if let statusItemError = error as? StatusItemError {
            errorMessage = statusItemError.localizedDescription
        } else {
            errorMessage = "Failed to create menu bar item: \(error.localizedDescription)"
        }
        
        print("Status item error: \(errorMessage)")
        statusItemError = errorMessage
        
        // Show error to user if needed
        lastErrorMessage = errorMessage
        showingErrorAlert = true
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 250, height: 200)
        popover?.behavior = .transient
        popover?.animates = true
        
        // Create SwiftUI view with environment object
        let menuView = MenuBarView().environmentObject(self)
        popover?.contentViewController = NSHostingController(rootView: menuView)
        
        print("Popover configured for SwiftUI menu content")
    }
    
    @objc private func statusItemClicked() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showMenu(relativeTo: button)
        }
    }
    
    // MARK: - Menu Positioning and Lifecycle
    
    /// Shows the menu with intelligent positioning and screen edge detection
    private func showMenu(relativeTo button: NSStatusBarButton) {
        guard let popover = popover else { return }
        
        // Calculate optimal positioning based on screen edges
        let positioning = calculateOptimalMenuPosition(for: button)
        
        // Configure popover appearance based on positioning
        configurePopoverAppearance(for: positioning)
        
        // Show popover with calculated position
        popover.show(
            relativeTo: button.bounds, 
            of: button, 
            preferredEdge: positioning.edge
        )
        
        // Set up popover lifecycle management
        setupPopoverLifecycleHandlers()
        
        print("Menu displayed with positioning: \(positioning)")
    }
    
    /// Calculates optimal menu position based on screen constraints
    private func calculateOptimalMenuPosition(for button: NSStatusBarButton) -> MenuPositioning {
        // Get button position in screen coordinates
        guard let buttonWindow = button.window else {
            return MenuPositioning(edge: .minY, alignment: .center)
        }
        
        let buttonRect = button.convert(button.bounds, to: nil)
        let buttonScreenRect = buttonWindow.convertToScreen(buttonRect)
        
        // Get screen bounds
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.visibleFrame
        
        // Calculate available space in each direction
        let spaceBelow = buttonScreenRect.minY - screenFrame.minY
        let spaceAbove = screenFrame.maxY - buttonScreenRect.maxY
        let spaceLeft = buttonScreenRect.minX - screenFrame.minX
        let spaceRight = screenFrame.maxX - buttonScreenRect.maxX
        
        // Menu dimensions (from popover content size)
        let menuHeight = popover?.contentSize.height ?? 200
        let menuWidth = popover?.contentSize.width ?? 250
        
        // Determine optimal edge
        var edge: NSRectEdge = .minY  // Default: below
        var alignment: MenuAlignment = .center
        
        // Check if menu fits below (preferred)
        if spaceBelow >= menuHeight {
            edge = .minY
        } else if spaceAbove >= menuHeight {
            edge = .maxY
        } else if spaceRight >= menuWidth {
            edge = .maxX
            alignment = .leading
        } else if spaceLeft >= menuWidth {
            edge = .minX
            alignment = .trailing
        } else {
            // Force below with scrolling if necessary
            edge = .minY
            // Adjust menu height to fit available space
            let adjustedHeight = max(spaceBelow - 20, 150) // Minimum 150px
            popover?.contentSize = NSSize(width: menuWidth, height: adjustedHeight)
        }
        
        return MenuPositioning(edge: edge, alignment: alignment)
    }
    
    /// Configures popover appearance based on positioning
    private func configurePopoverAppearance(for positioning: MenuPositioning) {
        guard let popover = popover else { return }
        
        // Configure popover appearance (use system appearance)
        popover.appearance = nil  // Use system appearance
        
        // Set up proper close behavior
        popover.behavior = .transient
        
        // Ensure animations are smooth
        popover.animates = true
    }
    
    /// Sets up popover lifecycle event handlers
    private func setupPopoverLifecycleHandlers() {
        // Add observers for popover lifecycle events
        // This helps us track menu state and handle edge cases
        
        NotificationCenter.default.addObserver(
            forName: NSPopover.willShowNotification,
            object: popover,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMenuWillShow()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSPopover.didCloseNotification,
            object: popover,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMenuDidClose()
            }
        }
    }
    
    /// Handles menu will show event
    private func handleMenuWillShow() {
        print("Menu will show")
        // Prepare menu state
        // Could refresh data, update permissions, etc.
    }
    
    /// Handles menu did close event
    private func handleMenuDidClose() {
        print("Menu did close")
        // Clean up any temporary state
        // Remove lifecycle observers to prevent memory leaks
        NotificationCenter.default.removeObserver(
            self,
            name: NSPopover.willShowNotification,
            object: popover
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSPopover.didCloseNotification,
            object: popover
        )
    }
    
    private func setupNotifications() {
        // Future: Set up additional notification monitoring
        // Global hotkeys are now handled by setupGlobalHotkeys()
    }
    
    // MARK: - Global Hotkey Setup
    
    private func setupGlobalHotkeys() {
        print("Setting up global hotkeys")
        
        Task {
            // Register the capture area hotkey
            let success = await hotkeyManager.registerCaptureAreaHotkey { [weak self] in
                Task { @MainActor in
                    print("🎯 Global hotkey triggered - Cmd+Shift+4")
                    self?.triggerCapture()
                }
            }
            
            if success {
                print("✅ Global hotkey registered successfully")
            } else {
                print("⚠️ Failed to register global hotkey: \(hotkeyManager.errorMessage ?? "Unknown error")")
                
                // If accessibility permission is needed, we can show a notification
                if !hotkeyManager.isAvailable {
                    print("💡 Accessibility permission required for global hotkeys")
                }
            }
        }
    }
    
    // MARK: - Termination Handling
    
    private func setupTerminationHandling() {
        // Register for application termination notifications
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleApplicationWillTerminate()
            }
        }
        
        // Register for system shutdown/logout notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willPowerOffNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSystemWillShutdown()
            }
        }
        
        // Register for user logout notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSessionChange()
            }
        }
        
        print("Application termination handling configured")
    }
    
    /// Handles application will terminate notification
    private func handleApplicationWillTerminate() {
        print("Application will terminate - performing cleanup")
        
        // Cancel any ongoing captures
        if isCapturing {
            print("Cancelling ongoing capture due to app termination")
            isCapturing = false
        }
        
        // Perform cleanup
        cleanup()
        
        // Give brief time for cleanup to complete
        Thread.sleep(forTimeInterval: 0.1)
        
        print("Application termination cleanup complete")
    }
    
    /// Handles system shutdown notification
    private func handleSystemWillShutdown() {
        print("System will shutdown - performing emergency cleanup")
        
        // Emergency cleanup - no time for delays
        if isCapturing {
            isCapturing = false
        }
        
        // Immediate cleanup
        cleanup()
        
        print("System shutdown cleanup complete")
    }
    
    /// Handles session changes (login/logout)
    private func handleSessionChange() {
        print("Session change detected - verifying app state")
        
        // Verify menu bar state after session changes
        if isVisible && statusItem == nil {
            // Recreate status item if needed after session change
            setupMenuBar()
        }
    }
    
    // MARK: - Menu Actions
    
    func triggerCapture() {
        print("🚀 [DEBUG] triggerCapture() called")
        Task {
            // Check permission before attempting capture
            if !permissionManager.canCapture {
                print("⚠️ [DEBUG] Permission not granted, showing permission dialog")
                await handlePermissionRequired()
                return
            }
            
            // Show area selection overlay
            print("🔍 [DEBUG] Showing area selection overlay")
            updatePerformanceStatus("Select area to capture...")
            
            overlayManager.showAreaSelection(
                onAreaSelected: { [weak self] rect in
                    Task { @MainActor in
                        await self?.handleAreaSelected(rect)
                    }
                },
                onCancelled: { [weak self] in
                    Task { @MainActor in
                        self?.handleCaptureCancelled()
                    }
                }
            )
        }
        print("🔍 [DEBUG] triggerCapture() task started")
    }
    
    private func handlePermissionRequired() async {
        print("Screen recording permission required")
        
        // Try to request permission
        let granted = await permissionManager.requestPermission()
        
        if !granted {
            // Show alert with instructions
            showingPermissionAlert = true
        }
    }
    
    /// Handles area selection completion
    private func handleAreaSelected(_ rect: CGRect) async {
        print("🔍 [DEBUG] handleAreaSelected() called with rect: \(rect)")
        
        // Set capturing state
        isCapturing = true
        updatePerformanceStatus("Capturing area...")
        
        defer {
            isCapturing = false
        }
        
        // Capture the selected area
        print("🔍 [DEBUG] Calling captureEngine.captureArea()...")
        if let image = await captureEngine.captureArea(rect) {
            print("✅ [DEBUG] Area captured successfully: \(image.width)x\(image.height)")
            
            // Show success feedback
            let imageSize = "\(image.width)x\(image.height)"
            await handleCaptureSuccess(imageSize: imageSize)
            
            // Save the image
            await saveImageToDesktop(image)
            
            // Update performance status
            updatePerformanceStatus(captureEngine.currentPerformanceMetrics)
            
        } else {
            print("❌ [DEBUG] Area capture failed - captureEngine returned nil")
            await handleCaptureError()
        }
    }
    
    /// Handles capture cancellation
    private func handleCaptureCancelled() {
        print("🔍 [DEBUG] handleCaptureCancelled() called")
        updatePerformanceStatus("Capture cancelled")
        
        // Brief delay then clear status
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            updatePerformanceStatus("")
        }
    }
    
    // MARK: - Enhanced User Feedback
    
    /// Handles capture success with user feedback
    private func handleCaptureSuccess(imageSize: String) async {
        lastSuccessMessage = "Screenshot captured successfully (\(imageSize))"
        showingSuccessNotification = true
        
        // Auto-hide success notification after 3 seconds
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        showingSuccessNotification = false
    }
    
    /// Handles capture errors with user-friendly messaging
    private func handleCaptureError() async {
        if let error = captureEngine.lastError {
            // Get user-friendly error message from the error handler
            let errorHandler = captureEngine.errorHandler
            lastErrorMessage = errorHandler.userFriendlyMessage(for: error)
            
            print("Detailed error: \(error.localizedDescription)")
            print("User-friendly message: \(lastErrorMessage)")
            
            // Show error alert
            showingErrorAlert = true
        } else {
            lastErrorMessage = "An unknown error occurred during screen capture."
            showingErrorAlert = true
        }
    }
    
    /// Updates performance status display
    private func updatePerformanceStatus(_ status: String) {
        performanceStatus = status
    }
    
    /// Gets recovery suggestion for current error
    var errorRecoverySuggestion: String {
        guard let error = captureEngine.lastError else { return "" }
        return captureEngine.errorHandler.recoverySuggestion(for: error)
    }
    
    /// Dismisses error alert and clears error state
    func dismissErrorAlert() {
        showingErrorAlert = false
        lastErrorMessage = ""
        captureEngine.clearError()
    }
    
    /// Dismisses success notification
    func dismissSuccessNotification() {
        showingSuccessNotification = false
        lastSuccessMessage = ""
    }
    
    // MARK: - Permission Management
    
    /// Opens System Preferences for screen recording permission
    func openSystemPreferences() {
        permissionManager.openSystemPreferences()
        showingPermissionAlert = false
    }
    
    /// Dismisses the permission alert
    func dismissPermissionAlert() {
        showingPermissionAlert = false
    }
    
    /// Gets the current permission status message
    var permissionStatusMessage: String {
        permissionManager.statusMessage
    }
    
    /// Whether capture is currently available
    var canCapture: Bool {
        permissionManager.canCapture
    }
    
    // MARK: - Permission and Security Debugging
    
    /// Performs comprehensive security and permission auditing for file system access
    private func auditFileSystemPermissions(for directoryURL: URL, directoryName: String) {
        let timestamp = DateFormatter().apply {
            $0.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        }.string(from: Date())
        
        print("🔐 [SECURITY] [\(timestamp)] Starting permission audit for \(directoryName)")
        print("   📁 Directory path: \(directoryURL.path)")
        
        // Check basic file manager permissions
        let isWritable = FileManager.default.isWritableFile(atPath: directoryURL.path)
        let isReadable = FileManager.default.isReadableFile(atPath: directoryURL.path)
        let isDeletable = FileManager.default.isDeletableFile(atPath: directoryURL.path)
        let exists = FileManager.default.fileExists(atPath: directoryURL.path)
        
        print("   ✅ Directory exists: \(exists)")
        print("   🔓 Writable: \(isWritable)")
        print("   👁️ Readable: \(isReadable)")
        print("   🗑️ Deletable: \(isDeletable)")
        
        // Check directory attributes and permissions
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: directoryURL.path)
            
            if let posixPermissions = attributes[.posixPermissions] as? NSNumber {
                let octalPermissions = String(posixPermissions.uint16Value, radix: 8)
                print("   🔢 POSIX permissions: \(octalPermissions)")
                
                // Decode permissions for user, group, and other
                let userPerms = (posixPermissions.uint16Value & 0o700) >> 6
                let groupPerms = (posixPermissions.uint16Value & 0o070) >> 3
                let otherPerms = posixPermissions.uint16Value & 0o007
                
                print("   👤 User permissions: \(userPerms) (\(permissionString(userPerms)))")
                print("   👥 Group permissions: \(groupPerms) (\(permissionString(groupPerms)))")
                print("   🌐 Other permissions: \(otherPerms) (\(permissionString(otherPerms)))")
            }
            
            if let owner = attributes[.ownerAccountName] as? String {
                print("   👤 Owner: \(owner)")
            }
            
            if let group = attributes[.groupOwnerAccountName] as? String {
                print("   👥 Group: \(group)")
            }
            
        } catch {
            print("   ⚠️ Could not read directory attributes: \(error)")
        }
        
        // Check app-specific security constraints
        print("   🛡️ App Security Context:")
        
        // Check if we're running in a sandboxed environment
        let isSandboxed = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
        print("   📦 Sandboxed: \(isSandboxed)")
        
        // Check bundle identifier
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        print("   🏷️ Bundle ID: \(bundleID)")
        
        // Check for file system entitlements
        print("   📋 Security Scoped Access:")
        let canStartAccessingSecurityScopedResource = directoryURL.startAccessingSecurityScopedResource()
        print("   🔓 Can access security scoped resource: \(canStartAccessingSecurityScopedResource)")
        
        if canStartAccessingSecurityScopedResource {
            directoryURL.stopAccessingSecurityScopedResource()
        }
        
        print("🔐 [SECURITY] [\(timestamp)] Permission audit completed for \(directoryName)")
    }
    
    /// Converts numeric permission value to human-readable string
    private func permissionString(_ permission: UInt16) -> String {
        var result = ""
        result += (permission & 4) != 0 ? "r" : "-"
        result += (permission & 2) != 0 ? "w" : "-"
        result += (permission & 1) != 0 ? "x" : "-"
        return result
    }
    
    /// Logs comprehensive app entitlements and security context
    private func logAppSecurityContext() {
        let timestamp = DateFormatter().apply {
            $0.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        }.string(from: Date())
        
        print("🛡️ [SECURITY] [\(timestamp)] App Security Context Analysis")
        
        // Bundle information
        let bundle = Bundle.main
        print("   📦 Bundle path: \(bundle.bundlePath)")
        print("   🏷️ Bundle ID: \(bundle.bundleIdentifier ?? "unknown")")
        print("   📋 Display name: \(bundle.infoDictionary?["CFBundleDisplayName"] as? String ?? "unknown")")
        
        // Executable information
        if let executablePath = bundle.executablePath {
            print("   ⚙️ Executable: \(executablePath)")
            
            // Check if executable exists and is readable
            let executableExists = FileManager.default.fileExists(atPath: executablePath)
            let executableReadable = FileManager.default.isReadableFile(atPath: executablePath)
            print("   ✅ Executable exists: \(executableExists)")
            print("   👁️ Executable readable: \(executableReadable)")
        }
        
        // Process information
        let processInfo = ProcessInfo.processInfo
        print("   🔢 Process ID: \(processInfo.processIdentifier)")
        print("   👤 User ID: \(getuid())")
        print("   👥 Group ID: \(getgid())")
        
        // Environment variables related to security
        print("   🌍 Security Environment Variables:")
        if let sandboxContainerID = processInfo.environment["APP_SANDBOX_CONTAINER_ID"] {
            print("      📦 Sandbox Container ID: \(sandboxContainerID)")
        } else {
            print("      📦 Sandbox Container ID: Not set (likely not sandboxed)")
        }
        
        if let homeDir = processInfo.environment["HOME"] {
            print("      🏠 Home directory: \(homeDir)")
        }
        
        if let tmpDir = processInfo.environment["TMPDIR"] {
            print("      📁 Temp directory: \(tmpDir)")
        }
        
        // Check for common security-related capabilities
        print("   🔐 Security Capabilities:")
        
        // Test ability to access various directories
        let testDirectories: [(String, FileManager.SearchPathDirectory)] = [
            ("Desktop", .desktopDirectory),
            ("Documents", .documentDirectory),
            ("Downloads", .downloadsDirectory),
            ("Pictures", .picturesDirectory),
            ("Movies", .moviesDirectory),
            ("Music", .musicDirectory)
        ]
        
        for (name, directory) in testDirectories {
            do {
                let url = try FileManager.default.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: false)
                let accessible = FileManager.default.fileExists(atPath: url.path)
                let writable = FileManager.default.isWritableFile(atPath: url.path)
                print("      📁 \(name): accessible=\(accessible), writable=\(writable)")
            } catch {
                print("      📁 \(name): Error accessing - \(error.localizedDescription)")
            }
        }
        
        print("🛡️ [SECURITY] [\(timestamp)] App Security Context Analysis complete")
    }
    
    // MARK: - File Saving
    
    /// Saves a captured image to Desktop with timestamp filename
    private func saveImageToDesktop(_ image: CGImage) async {
        // MARK: - Function Entry Logging
        let functionStartTime = Date()
        let timestamp = DateFormatter().apply {
            $0.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        }.string(from: functionStartTime)
        
        print("🚀 [DEBUG] [\(timestamp)] saveImageToDesktop() ENTRY - Function called")
        print("🔍 [DEBUG] [\(timestamp)] saveImageToDesktop() - Image details:")
        print("   📐 Dimensions: \(image.width) x \(image.height) pixels")
        print("   🎨 Color Space: \(image.colorSpace?.name as String? ?? "unknown")")
        print("   💾 Bits per component: \(image.bitsPerComponent)")
        print("   📊 Bits per pixel: \(image.bitsPerPixel)")
        print("   📏 Bytes per row: \(image.bytesPerRow)")
        
        updatePerformanceStatus("Saving image...")
        
        // MARK: - Security Context Logging (First Time Only for Performance)
        // Use a private static property to track if we've logged the security context
        if !MenuBarManager.hasLoggedSecurityContext {
            logAppSecurityContext()
            MenuBarManager.hasLoggedSecurityContext = true
        }
        
        do {
            // MARK: - Desktop Directory Resolution Logging
            print("🔍 [DEBUG] [\(timestamp)] Starting Desktop directory resolution...")
            var saveURL: URL
            var locationName: String
            
            // Try Desktop first with comprehensive logging
            do {
                print("🔍 [DEBUG] [\(timestamp)] Attempting FileManager.default.url(for: .desktopDirectory)...")
                saveURL = try FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                locationName = "Desktop"
                print("✅ [DEBUG] [\(timestamp)] Desktop URL resolution SUCCESS")
                print("   📁 Desktop path: \(saveURL.path)")
                print("   📁 Desktop absolute path: \(saveURL.absoluteString)")
                
                // Verify Desktop directory exists
                let desktopExists = FileManager.default.fileExists(atPath: saveURL.path)
                print("   ✅ Desktop directory exists: \(desktopExists)")
                
                if !desktopExists {
                    print("⚠️ [DEBUG] [\(timestamp)] Desktop directory does not exist, attempting to fall back...")
                    throw NSError(domain: "DirectoryNotFound", code: 1, userInfo: [NSLocalizedDescriptionKey: "Desktop directory not found"])
                }
                
            } catch {
                print("⚠️ [DEBUG] [\(timestamp)] Desktop not accessible, error details:")
                print("   ❌ Error domain: \(error.localizedDescription)")
                print("   ❌ Error code: \((error as NSError).code)")
                print("   ❌ Error description: \(error)")
                print("🔍 [DEBUG] [\(timestamp)] Falling back to Downloads directory...")
                
                saveURL = try FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                locationName = "Downloads"
                print("✅ [DEBUG] [\(timestamp)] Downloads URL resolution SUCCESS")
                print("   📁 Downloads path: \(saveURL.path)")
                print("   📁 Downloads absolute path: \(saveURL.absoluteString)")
            }
            
            // MARK: - Comprehensive Permission Auditing
            auditFileSystemPermissions(for: saveURL, directoryName: locationName)
            
            // MARK: - File System Permission Verification
            print("🔍 [DEBUG] [\(timestamp)] Checking file system permissions...")
            let isWritable = FileManager.default.isWritableFile(atPath: saveURL.path)
            let isReadable = FileManager.default.isReadableFile(atPath: saveURL.path)
            let isDeletable = FileManager.default.isDeletableFile(atPath: saveURL.path)
            
            print("   🔓 \(locationName) directory writable: \(isWritable)")
            print("   👁️ \(locationName) directory readable: \(isReadable)")  
            print("   🗑️ \(locationName) directory deletable: \(isDeletable)")
            
            // Check available disk space
            do {
                let resourceValues = try saveURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
                if let availableCapacity = resourceValues.volumeAvailableCapacity {
                    let availableMB = availableCapacity / (1024 * 1024)
                    print("   💾 Available disk space: \(availableMB) MB")
                }
            } catch {
                print("⚠️ [DEBUG] [\(timestamp)] Could not determine available disk space: \(error)")
            }
            
            // MARK: - Filename Generation and Validation
            let fileTimestamp = DateFormatter().apply {
                $0.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            }.string(from: Date())
            let filename = "screenit-\(fileTimestamp).png"
            let fileURL = saveURL.appendingPathComponent(filename)
            
            print("🔍 [DEBUG] [\(timestamp)] File path generation:")
            print("   📅 File timestamp: \(fileTimestamp)")
            print("   📄 Generated filename: \(filename)")
            print("   📁 Complete file path: \(fileURL.path)")
            print("   🌐 File URL: \(fileURL.absoluteString)")
            
            // Check if file already exists
            let fileAlreadyExists = FileManager.default.fileExists(atPath: fileURL.path)
            print("   ❓ File already exists: \(fileAlreadyExists)")
            
            if fileAlreadyExists {
                print("⚠️ [DEBUG] [\(timestamp)] File already exists - this shouldn't happen with timestamp!")
            }
            
            // MARK: - CGImageDestination Creation and Configuration
            print("🔍 [DEBUG] [\(timestamp)] Creating CGImageDestination...")
            print("   🎯 Target URL: \(fileURL)")
            print("   🏷️ UTI: \(UTType.png.identifier)")
            print("   📊 Image count: 1")
            
            guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                print("❌ [DEBUG] [\(timestamp)] CGImageDestination creation FAILED")
                print("   ❌ Target path: \(fileURL.path)")
                print("   ❌ UTI identifier: \(UTType.png.identifier)")
                print("   ❌ Possible causes:")
                print("      - Invalid file path")
                print("      - Insufficient permissions")
                print("      - Disk space full")
                print("      - Invalid UTI")
                
                await handleFileSaveError("Failed to create image destination for file: \(fileURL.lastPathComponent)")
                return
            }
            print("✅ [DEBUG] [\(timestamp)] CGImageDestination created successfully")
            
            // MARK: - Image Addition to Destination
            print("🔍 [DEBUG] [\(timestamp)] Adding image to destination...")
            let imageAddStartTime = Date()
            CGImageDestinationAddImage(destination, image, nil)
            let imageAddDuration = Date().timeIntervalSince(imageAddStartTime)
            print("✅ [DEBUG] [\(timestamp)] Image added to destination (took \(String(format: "%.3f", imageAddDuration)) seconds)")
            
            // MARK: - CGImageDestination Finalization
            print("🔍 [DEBUG] [\(timestamp)] Finalizing image destination...")
            let finalizeStartTime = Date()
            let finalizeResult = CGImageDestinationFinalize(destination)
            let finalizeDuration = Date().timeIntervalSince(finalizeStartTime)
            
            if finalizeResult {
                print("✅ [DEBUG] [\(timestamp)] CGImageDestinationFinalize SUCCESS (took \(String(format: "%.3f", finalizeDuration)) seconds)")
                
                // MARK: - Post-Save File System Verification
                print("🔍 [DEBUG] [\(timestamp)] Performing post-save file system verification...")
                
                // Check file existence
                let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
                print("   ✅ File exists on disk: \(fileExists)")
                
                if fileExists {
                    // Get detailed file attributes
                    do {
                        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                        let fileSize = fileAttributes[.size] as? Int64 ?? 0
                        let creationDate = fileAttributes[.creationDate] as? Date
                        let modificationDate = fileAttributes[.modificationDate] as? Date
                        let filePermissions = fileAttributes[.posixPermissions] as? NSNumber
                        
                        print("   📊 File size: \(fileSize) bytes (\(String(format: "%.2f", Double(fileSize) / 1024.0)) KB)")
                        print("   📅 Creation date: \(creationDate?.description ?? "unknown")")
                        print("   📅 Modification date: \(modificationDate?.description ?? "unknown")")
                        print("   🔐 Permissions: \(filePermissions?.stringValue ?? "unknown")")
                        
                        // Validate file size is reasonable (should be > 0 for a real image)
                        if fileSize > 0 {
                            print("✅ [DEBUG] [\(timestamp)] File size validation: PASSED (size > 0)")
                        } else {
                            print("❌ [DEBUG] [\(timestamp)] File size validation: FAILED (size = 0)")
                        }
                        
                    } catch {
                        print("⚠️ [DEBUG] [\(timestamp)] Could not get file attributes: \(error)")
                    }
                    
                    // Verify file is readable
                    let isFileReadable = FileManager.default.isReadableFile(atPath: fileURL.path)
                    print("   👁️ File is readable: \(isFileReadable)")
                    
                } else {
                    print("❌ [DEBUG] [\(timestamp)] CRITICAL ERROR: File does not exist despite successful finalize!")
                    print("   🔍 This indicates a potential issue with:")
                    print("      - File system permissions")
                    print("      - App sandboxing restrictions")
                    print("      - Asynchronous file system operations")
                    print("      - CGImageDestination behavior")
                }
                
                // MARK: - Function Success Exit
                let totalDuration = Date().timeIntervalSince(functionStartTime)
                print("✅ [DEBUG] [\(timestamp)] Image saved successfully")
                print("   📁 Final location: \(fileURL.path)")
                print("   ⏱️ Total operation time: \(String(format: "%.3f", totalDuration)) seconds")
                
                await handleFileSaveSuccess(fileURL: fileURL, locationName: locationName)
                
            } else {
                print("❌ [DEBUG] [\(timestamp)] CGImageDestinationFinalize FAILED")
                print("   ⏱️ Finalize attempt duration: \(String(format: "%.3f", finalizeDuration)) seconds")
                print("   🔍 Possible causes:")
                print("      - Insufficient disk space")
                print("      - File system permissions")
                print("      - Corrupted image data")
                print("      - Invalid destination configuration")
                print("      - System resource constraints")
                
                await handleFileSaveError("Failed to finalize image file at: \(fileURL.lastPathComponent)")
            }
            
        } catch {
            // MARK: - Exception Handling and Logging
            let totalDuration = Date().timeIntervalSince(functionStartTime)
            print("❌ [DEBUG] [\(timestamp)] EXCEPTION in saveImageToDesktop")
            print("   ⏱️ Time before exception: \(String(format: "%.3f", totalDuration)) seconds")
            print("   ❌ Exception type: \(type(of: error))")
            print("   ❌ Exception description: \(error.localizedDescription)")
            print("   ❌ Full error: \(error)")
            
            if let nsError = error as NSError? {
                print("   ❌ Error domain: \(nsError.domain)")
                print("   ❌ Error code: \(nsError.code)")
                print("   ❌ Error userInfo: \(nsError.userInfo)")
            }
            
            await handleFileSaveError("Failed to access Desktop directory: \(error.localizedDescription)")
        }
        
        // MARK: - Function Exit Logging
        let finalTimestamp = DateFormatter().apply {
            $0.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        }.string(from: Date())
        let totalExecutionTime = Date().timeIntervalSince(functionStartTime)
        
        print("🏁 [DEBUG] [\(finalTimestamp)] saveImageToDesktop() EXIT - Function completed")
        print("   ⏱️ Total execution time: \(String(format: "%.3f", totalExecutionTime)) seconds")
        print("   📊 Performance status: \(performanceStatus)")
    }
    
    /// Handles successful file save
    private func handleFileSaveSuccess(fileURL: URL, locationName: String) async {
        print("🎉 [DEBUG] handleFileSaveSuccess() called with URL: \(fileURL.path)")
        let fileName = fileURL.lastPathComponent
        updatePerformanceStatus("Image saved as \(fileName)")
        
        // Update success message to include file location
        lastSuccessMessage = "Screenshot saved to \(locationName) as \(fileName)"
        print("✅ [DEBUG] Success message set: \(lastSuccessMessage)")
        
        // Show brief success notification
        showingSuccessNotification = true
        print("🔍 [DEBUG] Success notification shown")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        showingSuccessNotification = false
        print("🔍 [DEBUG] Success notification hidden")
    }
    
    /// Handles file save errors
    private func handleFileSaveError(_ message: String) async {
        print("💥 [DEBUG] handleFileSaveError() called with message: \(message)")
        lastErrorMessage = """
        Failed to save screenshot.
        
        \(message)
        
        Please ensure you have write access to the Desktop and sufficient disk space.
        """
        print("❌ [DEBUG] Error message set: \(lastErrorMessage)")
        showingErrorAlert = true
        print("🚨 [DEBUG] Error alert shown")
        updatePerformanceStatus("Save failed")
    }
    
    // MARK: - Other Menu Actions
    
    func showHistory() {
        print("Show History triggered")
        // TODO: Implement history view in Phase 4
    }
    
    func showPreferences() {
        print("Preferences triggered")
        // TODO: Implement preferences window in Phase 5
    }
    
    func quitApp() {
        print("User requested app termination")
        
        // Perform graceful cleanup before terminating
        cleanup()
        
        // Brief delay to ensure cleanup completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("Terminating application")
            NSApplication.shared.terminate(nil)
        }
    }
    
    // MARK: - Menu Bar Visibility
    
    func toggleVisibility() {
        isVisible.toggle()
        updateMenuBarVisibility()
    }
    
    func hideMenuBar() {
        isVisible = false
        updateMenuBarVisibility()
    }
    
    func showMenuBar() {
        isVisible = true
        updateMenuBarVisibility()
    }
    
    private func updateMenuBarVisibility() {
        statusItem?.isVisible = isVisible
    }
    
    // MARK: - Menu Control
    
    /// Programmatically dismisses the menu if it's showing
    func dismissMenu() {
        popover?.performClose(nil)
    }
    
    /// Checks if the menu is currently visible
    var isMenuVisible: Bool {
        return popover?.isShown ?? false
    }
    
    // MARK: - Cleanup
    
    /// Manually cleanup the menu bar resources
    func cleanup() {
        print("MenuBarManager cleanup starting...")
        
        // Cancel any ongoing operations
        if isCapturing {
            print("Cancelling ongoing capture during cleanup")
            isCapturing = false
        }
        
        // Hide overlay if showing
        overlayManager.hideOverlay()
        
        // Unregister global hotkeys
        hotkeyManager.unregisterAllHotkeys()
        
        // Dismiss menu if showing
        dismissMenu()
        
        // Remove all notification observers (both NSNotificationCenter and NSWorkspace)
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        
        // Remove status item from menu bar
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
            print("Status item removed from menu bar")
        }
        
        // Clear popover and release resources
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            }
            popover.contentViewController = nil
            self.popover = nil
            print("Popover resources cleaned up")
        }
        
        // Clear any error states
        showingErrorAlert = false
        showingSuccessNotification = false
        showingPermissionAlert = false
        lastErrorMessage = ""
        lastSuccessMessage = ""
        
        print("MenuBarManager cleanup complete")
    }
    
    // MARK: - Status and Diagnostics
    
    /// Gets current capture engine status
    var captureEngineStatus: String {
        if isCapturing {
            return "Capturing..."
        } else if canCapture {
            return "Ready"
        } else {
            return "Permission required"
        }
    }
    
    /// Gets comprehensive error statistics
    var errorStatistics: String {
        return captureEngine.currentErrorStatistics
    }
    
    /// Gets current performance metrics
    var currentPerformanceMetrics: String {
        return captureEngine.currentPerformanceMetrics
    }
    
    /// Refreshes capture system content
    func refreshCaptureContent() {
        Task {
            await captureEngine.refreshAvailableContent()
            updatePerformanceStatus("Content refreshed")
        }
    }
    
    /// Resets all error and performance statistics
    func resetStatistics() {
        captureEngine.performanceTimer.resetMetrics()
        captureEngine.errorHandler.resetErrorCounts()
        updatePerformanceStatus("Statistics reset")
    }
}

// MARK: - Extensions

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}
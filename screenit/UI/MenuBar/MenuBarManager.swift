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
    
    // MARK: - Dependencies
    private let permissionManager = ScreenCapturePermissionManager()
    private let captureEngine = CaptureEngine.shared
    
    init() {
        setupMenuBar()
        setupNotifications()
        setupTerminationHandling()
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
        // Future: Set up global hotkey monitoring
        // For now, keyboard shortcuts are handled by MenuBarExtra
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
            
            // Set capturing state
            isCapturing = true
            updatePerformanceStatus("Starting capture...")
            print("🔍 [DEBUG] Capture state set, permission granted")
            
            defer {
                isCapturing = false
                print("🔍 [DEBUG] Capture state reset")
            }
            
            // Permission is granted, proceed with actual capture
            print("✅ [DEBUG] Capture Area triggered - permission granted")
            
            // For now, capture full screen (area selection comes in Phase 2)
            print("🔍 [DEBUG] Calling captureEngine.captureFullScreen()...")
            if let image = await captureEngine.captureFullScreen() {
                print("✅ [DEBUG] Screen captured successfully: \(image.width)x\(image.height)")
                
                // Show success feedback
                let imageSize = "\(image.width)x\(image.height)"
                print("🔍 [DEBUG] Calling handleCaptureSuccess...")
                await handleCaptureSuccess(imageSize: imageSize)
                
                // Save the image
                print("🔍 [DEBUG] Calling saveImageToDesktop...")
                await saveImageToDesktop(image)
                print("✅ [DEBUG] saveImageToDesktop call completed")
                
                // Update performance status
                updatePerformanceStatus(captureEngine.currentPerformanceMetrics)
                
            } else {
                print("❌ [DEBUG] Screen capture failed - captureEngine returned nil")
                await handleCaptureError()
            }
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
    
    // MARK: - File Saving
    
    /// Saves a captured image to Desktop with timestamp filename
    private func saveImageToDesktop(_ image: CGImage) async {
        print("🔍 [DEBUG] saveImageToDesktop() called - Image dimensions: \(image.width)x\(image.height)")
        updatePerformanceStatus("Saving image...")
        
        do {
            print("🔍 [DEBUG] Attempting to get Desktop directory URL...")
            var saveURL: URL
            var locationName: String
            
            // Try Desktop first
            do {
                saveURL = try FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                locationName = "Desktop"
                print("🔍 [DEBUG] Desktop URL resolved: \(saveURL.path)")
            } catch {
                print("⚠️ [DEBUG] Desktop not accessible, falling back to Downloads: \(error)")
                saveURL = try FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                locationName = "Downloads"
                print("🔍 [DEBUG] Downloads URL resolved: \(saveURL.path)")
            }
            
            let timestamp = DateFormatter().apply {
                $0.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            }.string(from: Date())
            let fileURL = saveURL.appendingPathComponent("screenit-\(timestamp).png")
            print("🔍 [DEBUG] Target file URL: \(fileURL.path)")
            
            // Check if save directory is writable
            let isWritable = FileManager.default.isWritableFile(atPath: saveURL.path)
            print("🔍 [DEBUG] \(locationName) directory writable: \(isWritable)")
            
            print("🔍 [DEBUG] Creating CGImageDestination...")
            guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                print("❌ [DEBUG] Failed to create CGImageDestination for: \(fileURL.path)")
                await handleFileSaveError("Failed to create image destination for file: \(fileURL.lastPathComponent)")
                return
            }
            print("✅ [DEBUG] CGImageDestination created successfully")
            
            print("🔍 [DEBUG] Adding image to destination...")
            CGImageDestinationAddImage(destination, image, nil)
            print("✅ [DEBUG] Image added to destination")
            
            print("🔍 [DEBUG] Finalizing image destination...")
            if CGImageDestinationFinalize(destination) {
                print("✅ [DEBUG] CGImageDestinationFinalize succeeded")
                
                // Verify file actually exists on disk
                let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
                print("🔍 [DEBUG] File exists on disk: \(fileExists)")
                
                if fileExists {
                    let fileAttributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
                    let fileSize = fileAttributes?[.size] as? Int64 ?? 0
                    print("🔍 [DEBUG] File size: \(fileSize) bytes")
                } else {
                    print("❌ [DEBUG] File does not exist despite successful finalize!")
                }
                
                print("✅ [DEBUG] Image saved to: \(fileURL.path)")
                await handleFileSaveSuccess(fileURL: fileURL, locationName: locationName)
            } else {
                print("❌ [DEBUG] CGImageDestinationFinalize failed")
                await handleFileSaveError("Failed to finalize image file at: \(fileURL.lastPathComponent)")
            }
        } catch {
            print("❌ [DEBUG] Exception in saveImageToDesktop: \(error)")
            await handleFileSaveError("Failed to access Desktop directory: \(error.localizedDescription)")
        }
        
        print("🔍 [DEBUG] saveImageToDesktop() completed")
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
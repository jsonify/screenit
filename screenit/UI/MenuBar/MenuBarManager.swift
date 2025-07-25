import SwiftUI
import Combine

@MainActor
class MenuBarManager: ObservableObject {
    @Published var isVisible: Bool = true
    @Published var showingPermissionAlert: Bool = false
    
    // MARK: - Dependencies
    private let permissionManager = ScreenCapturePermissionManager()
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Future: Set up global hotkey monitoring
        // For now, keyboard shortcuts are handled by MenuBarExtra
    }
    
    // MARK: - Menu Actions
    
    func triggerCapture() {
        Task {
            // Check permission before attempting capture
            if !permissionManager.canCapture {
                await handlePermissionRequired()
                return
            }
            
            // Permission is granted, proceed with capture
            print("Capture Area triggered - permission granted")
            // TODO: Implement actual capture functionality
        }
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
    
    func showHistory() {
        print("Show History triggered")
        // TODO: Implement history view in Phase 4
    }
    
    func showPreferences() {
        print("Preferences triggered")
        // TODO: Implement preferences window in Phase 5
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Menu Bar Visibility
    
    func toggleVisibility() {
        isVisible.toggle()
    }
    
    func hideMenuBar() {
        isVisible = false
    }
    
    func showMenuBar() {
        isVisible = true
    }
}
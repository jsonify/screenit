import SwiftUI
import Combine
import UniformTypeIdentifiers

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
            
            // Permission is granted, proceed with actual capture
            print("Capture Area triggered - permission granted")
            
            // Use CaptureEngine for actual screen capture
            let captureEngine = CaptureEngine.shared
            
            // For now, capture full screen (area selection comes in Phase 2)
            if let image = await captureEngine.captureFullScreen() {
                print("Screen captured successfully: \(image.width)x\(image.height)")
                await saveImageToDesktop(image)
            } else {
                print("Screen capture failed")
                if let error = await captureEngine.lastError {
                    print("Error: \(error.localizedDescription)")
                }
            }
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
    
    // MARK: - File Saving
    
    /// Saves a captured image to Desktop with timestamp filename
    private func saveImageToDesktop(_ image: CGImage) async {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let timestamp = DateFormatter().apply {
            $0.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        }.string(from: Date())
        let fileURL = desktopURL.appendingPathComponent("screenit-\(timestamp).png")
        
        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            print("Failed to create image destination")
            return
        }
        
        CGImageDestinationAddImage(destination, image, nil)
        
        if CGImageDestinationFinalize(destination) {
            print("Image saved to: \(fileURL.path)")
        } else {
            print("Failed to save image")
        }
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

// MARK: - Extensions

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}
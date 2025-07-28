import Foundation
@preconcurrency import ScreenCaptureKit
import OSLog

/// Manages screen capture permissions and user interface for permission requests
@MainActor
class ScreenCapturePermissionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var permissionStatus: PermissionStatus = .notDetermined
    @Published var isRequestingPermission: Bool = false
    @Published var permissionError: String?
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "PermissionManager")
    private var lastPermissionCheck: Date = .distantPast
    private let permissionCheckCooldown: TimeInterval = 2.0 // 2 seconds between checks
    private let devHelper = DevelopmentPermissionHelper()
    
    // MARK: - Permission Status Enum
    enum PermissionStatus {
        case notDetermined
        case granted
        case denied
        case restricted
        
        var description: String {
            switch self {
            case .notDetermined:
                return "Permission not yet requested"
            case .granted:
                return "Screen recording permission granted"
            case .denied:
                return "Screen recording permission denied"
            case .restricted:
                return "Screen recording restricted by system policy"
            }
        }
        
        var canCapture: Bool {
            return self == .granted
        }
    }
    
    // MARK: - Initialization
    init() {
        Task {
            await checkPermissionStatus()
        }
    }
    
    // MARK: - Permission Management
    
    /// Checks the current permission status without requesting
    func checkPermissionStatus() async {
        // Implement cooldown to prevent rapid-fire permission checks
        let now = Date()
        if now.timeIntervalSince(lastPermissionCheck) < permissionCheckCooldown {
            logger.debug("Permission check skipped due to cooldown")
            return
        }
        lastPermissionCheck = now
        
        logger.info("Checking screen capture permission status")
        
        // Try to get content to check actual capability (this is the primary method for checking permissions)
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            // If we get here, permission is granted
            permissionStatus = .granted
            permissionError = nil
            logger.info("Screen capture permission is granted - found \(content.displays.count) displays")
            
        } catch let error as NSError {
            logger.error("Screen capture permission check failed: \(error.localizedDescription)")
            permissionStatus = .notDetermined
            permissionError = "Unable to determine screen recording permission: \(error.localizedDescription)"
        }
    }
    
    /// Requests screen capture permission from the user
    func requestPermission() async -> Bool {
        logger.info("Requesting screen capture permission")
        
        // Check if we should skip the dialog in development
        if devHelper.shouldSkipPermissionDialog() {
            // Do a non-intrusive check first
            await checkPermissionStatus()
            if permissionStatus == .granted {
                logger.info("Permission already granted and acknowledged, skipping dialog")
                return true
            }
        }
        
        // First check if we already have permission to avoid duplicate dialogs
        await checkPermissionStatus()
        if permissionStatus == .granted {
            logger.info("Permission already granted, no need to request")
            devHelper.markPermissionAcknowledged()
            return true
        }
        
        isRequestingPermission = true
        permissionError = nil
        
        defer {
            isRequestingPermission = false
        }
        
        do {
            // Attempting to get shareable content will trigger the permission dialog if needed
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            // If we get here, permission was granted
            permissionStatus = .granted
            permissionError = nil
            devHelper.markPermissionAcknowledged()
            
            logger.info("Screen capture permission granted - found \(content.displays.count) displays")
            return true
            
        } catch let error as NSError {
            // Handle permission denial or other errors
            if error.domain == "com.apple.screencapturekit" {
                if error.localizedDescription.contains("declined") {
                    permissionStatus = .denied
                    permissionError = "Screen recording permission was denied. To enable screenshots, please:\n\n1. Open System Preferences\n2. Go to Privacy & Security\n3. Click Screen Recording\n4. Enable screenit"
                } else {
                    permissionStatus = .restricted
                    permissionError = "Screen recording is restricted by system policy."
                }
            } else {
                permissionStatus = .notDetermined
                permissionError = "Permission request failed: \(error.localizedDescription)"
            }
            
            logger.error("Screen capture permission request failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Opens System Preferences to the Screen Recording privacy settings
    func openSystemPreferences() {
        logger.info("Opening System Preferences for screen recording settings")
        
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
    
    /// Clears any permission error
    func clearError() {
        permissionError = nil
    }
    
    /// Refreshes permission status (useful after user changes system settings)
    func refreshPermissionStatus() async {
        logger.info("Refreshing permission status")
        await checkPermissionStatus()
    }
    
    /// Forces a permission check bypassing cooldown (use sparingly)
    func forcePermissionCheck() async {
        logger.info("Forcing permission status check (bypassing cooldown)")
        lastPermissionCheck = .distantPast // Reset cooldown
        await checkPermissionStatus()
    }
    
    // MARK: - Convenience Properties
    
    /// Whether the app can currently capture screen content
    var canCapture: Bool {
        return permissionStatus.canCapture
    }
    
    /// User-friendly status message
    var statusMessage: String {
        if let error = permissionError {
            return error
        }
        return permissionStatus.description
    }
}
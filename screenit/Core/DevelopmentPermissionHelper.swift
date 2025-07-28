import Foundation
import OSLog

/// Helper to manage permission dialogs during development
/// Addresses the issue where permission dialogs appear repeatedly during development builds
class DevelopmentPermissionHelper {
    
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "DevPermissionHelper")
    private let userDefaults = UserDefaults.standard
    
    // Key to track permission dialog acknowledgment
    private let permissionAcknowledgedKey = "screenit.permission.acknowledged"
    
    /// Check if user has previously acknowledged the permission dialog
    var hasAcknowledgedPermission: Bool {
        get {
            userDefaults.bool(forKey: permissionAcknowledgedKey)
        }
        set {
            userDefaults.set(newValue, forKey: permissionAcknowledgedKey)
        }
    }
    
    /// Should we skip showing permission dialog based on development context
    func shouldSkipPermissionDialog() -> Bool {
        // In development builds, if user has already granted permission
        // and acknowledged it before, we can skip the dialog
        #if DEBUG
        if hasAcknowledgedPermission {
            logger.debug("Skipping permission dialog - previously acknowledged in development")
            return true
        }
        #endif
        
        return false
    }
    
    /// Mark that user has dealt with the permission dialog
    func markPermissionAcknowledged() {
        hasAcknowledgedPermission = true
        logger.info("Permission dialog acknowledged")
    }
    
    /// Reset permission acknowledgment (useful for testing)
    func resetPermissionAcknowledgment() {
        userDefaults.removeObject(forKey: permissionAcknowledgedKey)
        logger.info("Permission acknowledgment reset")
    }
}
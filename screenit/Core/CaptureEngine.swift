import Foundation
import CoreGraphics
import ScreenCaptureKit
import OSLog

/// Core engine for screen capture functionality using ScreenCaptureKit
@MainActor
class CaptureEngine: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CaptureEngine()
    
    // MARK: - Published Properties
    @Published var authorizationStatus: String = "checking"
    @Published var isCapturing: Bool = false
    @Published var lastError: CaptureError?
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "CaptureEngine")
    private let scCaptureManager = SCCaptureManager()
    private let permissionManager = ScreenCapturePermissionManager()
    
    // MARK: - Initialization
    private init() {
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization Management
    
    /// Updates the current authorization status using real ScreenCaptureKit permission
    func updateAuthorizationStatus() async {
        logger.info("Checking ScreenCaptureKit authorization status")
        
        await permissionManager.checkPermissionStatus()
        
        switch permissionManager.permissionStatus {
        case .granted:
            authorizationStatus = "authorized"
        case .denied:
            authorizationStatus = "denied"
        case .restricted:
            authorizationStatus = "restricted"
        case .notDetermined:
            authorizationStatus = "not_determined"
        }
        
        logger.info("Authorization status updated: \(self.authorizationStatus)")
    }
    
    /// Requests screen capture authorization from the user
    func requestAuthorization() async -> Bool {
        logger.info("Requesting screen capture authorization")
        
        let granted = await permissionManager.requestPermission()
        await updateAuthorizationStatus()
        
        logger.info("Authorization request result: \(granted)")
        return granted
    }
    
    // MARK: - Content Discovery
    
    /// Refreshes the available shareable content
    func refreshAvailableContent() async {
        logger.info("Refreshing available content")
        await scCaptureManager.refreshShareableContent()
        
        if let error = scCaptureManager.captureError {
            lastError = error
            logger.error("Content refresh failed: \(error.localizedDescription)")
        } else {
            lastError = nil
            logger.info("Available content refreshed: \(scCaptureManager.availableDisplays.count) displays")
        }
    }
    
    // MARK: - Screen Capture
    
    /// Captures a screenshot of the entire screen using ScreenCaptureKit
    func captureFullScreen() async -> CGImage? {
        logger.info("Starting full screen capture with ScreenCaptureKit")
        
        guard authorizationStatus == "authorized" else {
            logger.error("Screen capture not authorized")
            lastError = CaptureError.notAuthorized
            return nil
        }
        
        isCapturing = true
        lastError = nil
        
        defer {
            isCapturing = false
        }
        
        // Use SCCaptureManager for real screen capture
        let image = await scCaptureManager.captureFullScreen()
        
        if let error = scCaptureManager.captureError {
            lastError = error
            logger.error("Screen capture failed: \(error.localizedDescription)")
            return nil
        }
        
        if let image = image {
            logger.info("Screen capture successful: \(image.width)x\(image.height)")
        }
        
        return image
    }
    
    /// Captures a screenshot of a specific area using ScreenCaptureKit
    func captureArea(_ rect: CGRect) async -> CGImage? {
        logger.info("Starting area capture with ScreenCaptureKit: \(rect.width)x\(rect.height)")
        
        guard authorizationStatus == "authorized" else {
            logger.error("Screen capture not authorized")
            lastError = CaptureError.notAuthorized
            return nil
        }
        
        isCapturing = true
        lastError = nil
        
        defer {
            isCapturing = false
        }
        
        // Use SCCaptureManager for direct area capture
        let image = await scCaptureManager.captureArea(rect)
        
        if let error = scCaptureManager.captureError {
            lastError = error
            logger.error("Area capture failed: \(error.localizedDescription)")
            return nil
        }
        
        if let image = image {
            logger.info("Area capture successful: \(image.width)x\(image.height)")
        }
        
        return image
    }
    
    // MARK: - Utility Methods
    
    /// Clears the last error
    func clearError() {
        lastError = nil
        scCaptureManager.clearError()
    }
    
    /// Gets the primary display bounds from ScreenCaptureKit
    var primaryDisplayBounds: CGRect {
        guard let display = scCaptureManager.primaryDisplay else {
            // Fallback to standard size if no display available
            return CGRect(x: 0, y: 0, width: 1920, height: 1080)
        }
        
        return scCaptureManager.displayBounds(for: display)
    }
    
    /// Whether capture functionality is available
    var canCapture: Bool {
        return authorizationStatus == "authorized" && scCaptureManager.canCapture
    }
}

// MARK: - Error Types

enum CaptureError: LocalizedError, Equatable {
    case notAuthorized
    case authorizationFailed(Error)
    case contentDiscoveryFailed(Error)
    case noDisplaysAvailable
    case captureFailed(Error)
    case imageCroppingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Screen capture permission not granted"
        case .authorizationFailed(let error):
            return "Authorization failed: \(error.localizedDescription)"
        case .contentDiscoveryFailed(let error):
            return "Failed to discover screen content: \(error.localizedDescription)"
        case .noDisplaysAvailable:
            return "No displays available for capture"
        case .captureFailed(let error):
            return "Screen capture failed: \(error.localizedDescription)"
        case .imageCroppingFailed:
            return "Failed to crop captured image"
        }
    }
    
    // MARK: - Equatable
    static func == (lhs: CaptureError, rhs: CaptureError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized),
             (.noDisplaysAvailable, .noDisplaysAvailable),
             (.imageCroppingFailed, .imageCroppingFailed):
            return true
        case (.authorizationFailed(let lhsError), .authorizationFailed(let rhsError)),
             (.contentDiscoveryFailed(let lhsError), .contentDiscoveryFailed(let rhsError)),
             (.captureFailed(let lhsError), .captureFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
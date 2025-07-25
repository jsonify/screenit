import Foundation
import CoreGraphics
import OSLog

/// Core engine for screen capture functionality
class CaptureEngine: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CaptureEngine()
    
    // MARK: - Published Properties
    @Published var authorizationStatus: String = "authorized" // Simplified for now
    @Published var isCapturing: Bool = false
    @Published var lastError: CaptureError?
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "CaptureEngine")
    
    // MARK: - Initialization
    private init() {
        updateAuthorizationStatus()
    }
    
    // MARK: - Authorization Management
    
    /// Updates the current authorization status
    func updateAuthorizationStatus() {
        // For now, assume we have authorization
        // In a real implementation, this would check ScreenCaptureKit authorization
        authorizationStatus = "authorized"
        logger.info("Authorization status updated: \(self.authorizationStatus)")
    }
    
    /// Requests screen capture authorization from the user
    func requestAuthorization() async -> Bool {
        logger.info("Requesting screen capture authorization")
        
        // Simulate authorization request
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        Task { @MainActor in
            self.updateAuthorizationStatus()
        }
        
        logger.info("Authorization request result: true")
        return true
    }
    
    // MARK: - Content Discovery
    
    /// Refreshes the available shareable content
    func refreshAvailableContent() async {
        logger.info("Refreshing available content")
        // Simulate content discovery
        logger.info("Available content refreshed: 1 displays, 0 windows")
    }
    
    // MARK: - Screen Capture
    
    /// Captures a screenshot of the entire screen
    func captureFullScreen() async -> CGImage? {
        logger.info("Starting full screen capture")
        
        guard authorizationStatus == "authorized" else {
            logger.error("Screen capture not authorized")
            Task { @MainActor in
                self.lastError = CaptureError.notAuthorized
            }
            return nil
        }
        
        Task { @MainActor in
            self.isCapturing = true
            self.lastError = nil
        }
        
        defer {
            Task { @MainActor in
                self.isCapturing = false
            }
        }
        
        do {
            // Create a placeholder image for testing
            // In a real implementation, this would use ScreenCaptureKit
            let width = 1920
            let height = 1080
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw CaptureError.captureFailed(NSError(domain: "CaptureEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create graphics context"]))
            }
            
            // Fill with a gradient background to simulate a screenshot
            context.setFillColor(CGColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            
            guard let screenshot = context.makeImage() else {
                throw CaptureError.captureFailed(NSError(domain: "CaptureEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from context"]))
            }
            
            logger.info("Screen capture successful: \(screenshot.width)x\(screenshot.height)")
            return screenshot
            
        } catch {
            logger.error("Screen capture failed: \(error.localizedDescription)")
            Task { @MainActor in
                self.lastError = CaptureError.captureFailed(error)
            }
            return nil
        }
    }
    
    /// Captures a screenshot of a specific area
    func captureArea(_ rect: CGRect) async -> CGImage? {
        logger.info("Starting area capture: \(rect.width)x\(rect.height)")
        
        guard let fullScreenImage = await captureFullScreen() else {
            return nil
        }
        
        // Crop the full screen image to the specified area
        guard let croppedImage = fullScreenImage.cropping(to: rect) else {
            Task { @MainActor in
                self.lastError = CaptureError.imageCroppingFailed
            }
            return nil
        }
        
        logger.info("Area capture successful: \(croppedImage.width)x\(croppedImage.height)")
        return croppedImage
    }
    
    // MARK: - Utility Methods
    
    /// Clears the last error
    func clearError() {
        lastError = nil
    }
    
    /// Gets the primary display bounds
    var primaryDisplayBounds: CGRect {
        // Return a standard display size for testing
        return CGRect(x: 0, y: 0, width: 1920, height: 1080)
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
import Foundation
import ScreenCaptureKit
import OSLog

/// Wrapper class for ScreenCaptureKit capture operations
@MainActor
class SCCaptureManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isCapturing: Bool = false
    @Published var availableDisplays: [SCDisplay] = []
    @Published var captureError: CaptureError?
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "SCCaptureManager")
    private var shareableContent: SCShareableContent?
    
    // MARK: - Initialization
    init() {
        Task {
            await refreshShareableContent()
        }
    }
    
    // MARK: - Content Discovery
    
    /// Refreshes the available shareable content (displays and windows)
    func refreshShareableContent() async {
        logger.info("Refreshing shareable content")
        
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            self.shareableContent = content
            self.availableDisplays = content.displays
            self.captureError = nil
            
            logger.info("Found \(content.displays.count) displays and \(content.windows.count) windows")
            
        } catch {
            logger.error("Failed to refresh shareable content: \(error.localizedDescription)")
            self.captureError = CaptureError.contentDiscoveryFailed(error)
            self.availableDisplays = []
        }
    }
    
    // MARK: - Display Information
    
    /// Gets the primary display
    var primaryDisplay: SCDisplay? {
        return availableDisplays.first
    }
    
    /// Gets display bounds for a given display
    func displayBounds(for display: SCDisplay) -> CGRect {
        return CGRect(
            x: 0,
            y: 0,
            width: display.width,
            height: display.height
        )
    }
    
    // MARK: - Screen Capture
    
    /// Captures the full screen
    func captureFullScreen() async -> CGImage? {
        guard let display = primaryDisplay else {
            logger.error("No primary display available for capture")
            captureError = CaptureError.noDisplaysAvailable
            return nil
        }
        
        return await captureDisplay(display)
    }
    
    /// Captures a specific display
    func captureDisplay(_ display: SCDisplay) async -> CGImage? {
        logger.info("Starting display capture: \(display.displayID)")
        
        isCapturing = true
        captureError = nil
        
        defer {
            isCapturing = false
        }
        
        do {
            // Create content filter for the display
            let filter = SCContentFilter(display: display, excludingWindows: [])
            
            // Configure capture with high quality settings
            let configuration = SCStreamConfiguration()
            configuration.width = display.width
            configuration.height = display.height
            configuration.pixelFormat = kCVPixelFormatType_32BGRA
            configuration.colorSpaceName = CGColorSpace.sRGB
            configuration.showsCursor = false
            
            // Perform the capture
            let sample = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
            
            logger.info("Display capture successful: \(sample.width)x\(sample.height)")
            return sample
            
        } catch {
            logger.error("Display capture failed: \(error.localizedDescription)")
            captureError = CaptureError.captureFailed(error)
            return nil
        }
    }
    
    /// Captures a specific area of the screen
    func captureArea(_ rect: CGRect, from display: SCDisplay? = nil) async -> CGImage? {
        logger.info("Starting area capture: \(rect.width)x\(rect.height) at (\(rect.minX), \(rect.minY))")
        
        let targetDisplay = display ?? primaryDisplay
        guard let targetDisplay = targetDisplay else {
            logger.error("No display available for area capture")
            captureError = CaptureError.noDisplaysAvailable
            return nil
        }
        
        isCapturing = true
        captureError = nil
        
        defer {
            isCapturing = false
        }
        
        do {
            // Create content filter for the display
            let filter = SCContentFilter(display: targetDisplay, excludingWindows: [])
            
            // Configure capture for the specific area
            let configuration = SCStreamConfiguration()
            configuration.width = Int(rect.width)
            configuration.height = Int(rect.height)
            configuration.pixelFormat = kCVPixelFormatType_32BGRA
            configuration.colorSpaceName = CGColorSpace.sRGB
            configuration.showsCursor = false
            
            // Set the source rect for cropping
            configuration.sourceRect = rect
            
            // Perform the capture
            let sample = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
            
            logger.info("Area capture successful: \(sample.width)x\(sample.height)")
            return sample
            
        } catch {
            logger.error("Area capture failed: \(error.localizedDescription)")
            captureError = CaptureError.captureFailed(error)
            return nil
        }
    }
    
    // MARK: - Utility Methods
    
    /// Clears any capture error
    func clearError() {
        captureError = nil
    }
    
    /// Checks if capture is available (displays found and no errors)
    var canCapture: Bool {
        return !availableDisplays.isEmpty && captureError == nil
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
    case invalidCaptureArea
    
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
        case .invalidCaptureArea:
            return "Invalid capture area specified"
        }
    }
    
    // MARK: - Equatable
    static func == (lhs: CaptureError, rhs: CaptureError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized),
             (.noDisplaysAvailable, .noDisplaysAvailable),
             (.imageCroppingFailed, .imageCroppingFailed),
             (.invalidCaptureArea, .invalidCaptureArea):
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
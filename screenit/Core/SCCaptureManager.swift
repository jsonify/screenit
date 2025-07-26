import Foundation
@preconcurrency import ScreenCaptureKit
import OSLog

/// Wrapper class for ScreenCaptureKit capture operations
@MainActor
class SCCaptureManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isCapturing: Bool = false
    @Published var availableDisplays: [SCDisplay] = []
    @Published var captureError: CaptureError?
    
    // MARK: - Enhanced Supporting Classes
    private let configurationManager = CaptureConfigurationManager()
    private let errorHandler = CaptureErrorHandler()
    
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
            let captureError = CaptureError.contentDiscoveryFailed(error)
            logger.error("Failed to refresh shareable content: \(error.localizedDescription)")
            errorHandler.logError(captureError, context: "Refreshing shareable content")
            
            self.captureError = captureError
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
            let error = CaptureError.noDisplaysAvailable
            logger.error("No primary display available for capture")
            errorHandler.logError(error, context: "Full screen capture - no primary display")
            captureError = error
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
            
            // Use configurationManager for optimal capture settings
            let configuration = configurationManager.optimalConfiguration(for: display)
            
            // Validate configuration before use
            guard configurationManager.isValidConfiguration(configuration) else {
                let error = CaptureError.invalidCaptureArea
                logger.error("Invalid capture configuration for display \(display.displayID)")
                errorHandler.logError(error, context: "Display capture configuration validation")
                captureError = error
                return nil
            }
            
            logger.debug("Using optimal configuration: \(self.configurationManager.configurationDescription(configuration))")
            
            // Perform the capture
            let sample = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
            
            logger.info("Display capture successful: \(sample.width)x\(sample.height)")
            return sample
            
        } catch {
            let captureError = CaptureError.captureFailed(error)
            logger.error("Display capture failed: \(error.localizedDescription)")
            errorHandler.logError(captureError, context: "Display capture for display \(display.displayID)")
            
            self.captureError = captureError
            return nil
        }
    }
    
    /// Captures a specific area of the screen
    func captureArea(_ rect: CGRect, from display: SCDisplay? = nil) async -> CGImage? {
        logger.info("Starting area capture: \(rect.width)x\(rect.height) at (\(rect.minX), \(rect.minY))")
        
        let targetDisplay = display ?? primaryDisplay
        guard let targetDisplay = targetDisplay else {
            let error = CaptureError.noDisplaysAvailable
            logger.error("No display available for area capture")
            errorHandler.logError(error, context: "Area capture - no display available")
            captureError = error
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
            
            // Use configurationManager for optimal area capture settings
            let configuration = configurationManager.configuration(for: rect, on: targetDisplay)
            
            // Validate configuration before use
            guard configurationManager.isValidConfiguration(configuration) else {
                let error = CaptureError.invalidCaptureArea
                logger.error("Invalid capture configuration for area \(rect.debugDescription)")
                errorHandler.logError(error, context: "Area capture configuration validation")
                captureError = error
                return nil
            }
            
            logger.debug("Using area configuration: \(self.configurationManager.configurationDescription(configuration))")
            
            // Perform the capture
            let sample = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
            
            logger.info("Area capture successful: \(sample.width)x\(sample.height)")
            return sample
            
        } catch {
            let captureError = CaptureError.captureFailed(error)
            logger.error("Area capture failed: \(error.localizedDescription)")
            errorHandler.logError(captureError, context: "Area capture for rect \(rect) on display \(targetDisplay.displayID)")
            
            self.captureError = captureError
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
    
    // MARK: - Enhanced Utility Methods
    
    /// Gets user-friendly error message for the current error
    var userFriendlyErrorMessage: String? {
        guard let error = captureError else { return nil }
        return errorHandler.userFriendlyMessage(for: error)
    }
    
    /// Gets recovery suggestion for the current error
    var errorRecoverySuggestion: String? {
        guard let error = captureError else { return nil }
        return errorHandler.recoverySuggestion(for: error)
    }
    
    /// Gets error statistics report
    var errorStatistics: String {
        return errorHandler.errorReport
    }
    
    /// Creates optimal configuration for performance mode
    /// - Parameters:
    ///   - mode: Performance mode to optimize for
    ///   - display: Target display (uses primary if nil)
    /// - Returns: Optimized configuration or nil if no display available
    func createOptimalConfiguration(for mode: CaptureConfigurationManager.PerformanceMode, display: SCDisplay? = nil) -> SCStreamConfiguration? {
        let targetDisplay = display ?? primaryDisplay
        guard let targetDisplay = targetDisplay else { return nil }
        
        return configurationManager.configuration(for: mode, display: targetDisplay)
    }
    
    /// Estimates memory usage for a given area
    /// - Parameter rect: Area to estimate memory usage for
    /// - Returns: Estimated memory usage in bytes
    func estimatedMemoryUsage(for rect: CGRect) -> UInt64 {
        let config = configurationManager.defaultConfiguration()
        config.width = Int(rect.width)
        config.height = Int(rect.height)
        return configurationManager.estimatedMemoryUsage(for: config)
    }
}

// MARK: - Error Types

enum CaptureError: LocalizedError, Equatable, Hashable {
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
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        switch self {
        case .notAuthorized:
            hasher.combine(0)
        case .authorizationFailed(let error):
            hasher.combine(1)
            hasher.combine(error.localizedDescription)
        case .contentDiscoveryFailed(let error):
            hasher.combine(2)
            hasher.combine(error.localizedDescription)
        case .noDisplaysAvailable:
            hasher.combine(3)
        case .captureFailed(let error):
            hasher.combine(4)
            hasher.combine(error.localizedDescription)
        case .imageCroppingFailed:
            hasher.combine(5)
        case .invalidCaptureArea:
            hasher.combine(6)
        }
    }
}
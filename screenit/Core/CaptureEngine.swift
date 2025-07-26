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
    
    // MARK: - Enhanced Supporting Classes
    let performanceTimer = CapturePerformanceTimer()
    let errorHandler = CaptureErrorHandler()
    let configurationManager = CaptureConfigurationManager()
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "CaptureEngine")
    private let scCaptureManager = SCCaptureManager()
    private let permissionManager = ScreenCapturePermissionManager()
    private var lastCapturedImage: CGImage?
    
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
            logger.info("Available content refreshed: \(self.scCaptureManager.availableDisplays.count) displays")
        }
    }
    
    // MARK: - Screen Capture
    
    /// Captures a screenshot of the entire screen using ScreenCaptureKit
    func captureFullScreen() async -> CGImage? {
        logger.info("Starting full screen capture with ScreenCaptureKit")
        
        // Start performance monitoring
        performanceTimer.startTimer()
        
        guard authorizationStatus == "authorized" else {
            let error = CaptureError.notAuthorized
            lastError = error
            errorHandler.logError(error, context: "Full screen capture attempted without authorization")
            logger.error("Screen capture not authorized")
            return nil
        }
        
        isCapturing = true
        lastError = nil
        
        defer {
            isCapturing = false
            
            // Record performance metrics
            let duration = performanceTimer.stopTimer()
            if let image = lastCapturedImage {
                let imageSize = CGSize(width: image.width, height: image.height)
                let memoryUsage = configurationManager.estimatedMemoryUsage(for: 
                    configurationForImageSize(imageSize))
                
                performanceTimer.recordCaptureMetrics(
                    duration: duration,
                    imageSize: imageSize,
                    memoryUsage: memoryUsage
                )
                
                logger.info("Capture completed in \(String(format: "%.3f", duration))s, \(imageSize.width)x\(imageSize.height), \(self.formatMemorySize(memoryUsage))")
            }
        }
        
        // Use SCCaptureManager for real screen capture
        let image = await scCaptureManager.captureFullScreen()
        
        if let error = scCaptureManager.captureError {
            lastError = error
            errorHandler.logError(error, context: "Full screen capture operation")
            logger.error("Screen capture failed: \(error.localizedDescription)")
            return nil
        }
        
        if let image = image {
            logger.info("Screen capture successful: \(image.width)x\(image.height)")
            lastCapturedImage = image
        }
        
        return image
    }
    
    /// Captures a screenshot of a specific area using ScreenCaptureKit
    func captureArea(_ rect: CGRect) async -> CGImage? {
        logger.info("Starting area capture with ScreenCaptureKit: \(rect.width)x\(rect.height)")
        
        // Validate capture area
        guard rect.width > 0 && rect.height > 0 else {
            let error = CaptureError.invalidCaptureArea
            lastError = error
            errorHandler.logError(error, context: "Area capture with invalid dimensions: \(rect)")
            return nil
        }
        
        // Start performance monitoring
        performanceTimer.startTimer()
        
        guard authorizationStatus == "authorized" else {
            let error = CaptureError.notAuthorized
            lastError = error
            errorHandler.logError(error, context: "Area capture attempted without authorization")
            logger.error("Screen capture not authorized")
            return nil
        }
        
        isCapturing = true
        lastError = nil
        
        defer {
            isCapturing = false
            
            // Record performance metrics
            let duration = performanceTimer.stopTimer()
            if let image = lastCapturedImage {
                let imageSize = CGSize(width: image.width, height: image.height)
                let memoryUsage = configurationManager.estimatedMemoryUsage(for: 
                    configurationForImageSize(imageSize))
                
                performanceTimer.recordCaptureMetrics(
                    duration: duration,
                    imageSize: imageSize,
                    memoryUsage: memoryUsage
                )
                
                logger.info("Area capture completed in \(String(format: "%.3f", duration))s, \(imageSize.width)x\(imageSize.height), \(self.formatMemorySize(memoryUsage))")
            }
        }
        
        // Use SCCaptureManager for direct area capture
        let image = await scCaptureManager.captureArea(rect)
        
        if let error = scCaptureManager.captureError {
            lastError = error
            errorHandler.logError(error, context: "Area capture operation for rect: \(rect)")
            logger.error("Area capture failed: \(error.localizedDescription)")
            return nil
        }
        
        if let image = image {
            logger.info("Area capture successful: \(image.width)x\(image.height)")
            lastCapturedImage = image
        }
        
        return image
    }
    
    // MARK: - Utility Methods
    
    /// Clears the last error
    func clearError() {
        lastError = nil
        scCaptureManager.clearError()
        logger.debug("Cleared capture errors")
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
    
    // MARK: - Enhanced Utility Methods
    
    /// Creates a configuration for an image size
    private func configurationForImageSize(_ size: CGSize) -> SCStreamConfiguration {
        let config = configurationManager.defaultConfiguration()
        config.width = Int(size.width)
        config.height = Int(size.height)
        return config
    }
    
    /// Formats memory size in human-readable format
    private func formatMemorySize(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        if mb >= 1.0 {
            return String(format: "%.1fMB", mb)
        } else {
            let kb = Double(bytes) / 1024
            return String(format: "%.1fKB", kb)
        }
    }
    
    /// Gets current performance metrics
    var currentPerformanceMetrics: String {
        return performanceTimer.performanceReport
    }
    
    /// Gets current error statistics
    var currentErrorStatistics: String {
        return errorHandler.errorReport
    }
}


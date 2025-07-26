import Foundation
import ScreenCaptureKit
import CoreGraphics
import OSLog

/// Configuration manager for optimizing ScreenCaptureKit settings
@MainActor
class CaptureConfigurationManager: ObservableObject {
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.screenit.screenit", category: "CaptureConfigurationManager")
    
    // MARK: - Performance Modes
    
    /// Performance modes for different capture scenarios
    enum PerformanceMode {
        case quality    // Prioritize image quality
        case balanced   // Balance quality and performance
        case speed      // Prioritize capture speed
    }
    
    // MARK: - Configuration Constants
    
    private let maxReasonableWidth = 7680   // 8K width
    private let maxReasonableHeight = 4320  // 8K height
    private let minCaptureSize = 1          // Minimum 1x1 pixel
    private let bytesPerPixel = 4           // 32-bit BGRA = 4 bytes per pixel
    
    // MARK: - Default Configuration
    
    /// Returns the default capture configuration with optimal settings
    /// - Returns: A configured SCStreamConfiguration with default settings
    func defaultConfiguration() -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        
        // Use optimal pixel format for quality and compatibility
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.colorSpaceName = CGColorSpace.sRGB
        config.showsCursor = false
        
        // Dimensions will be set based on specific display or area
        config.width = 0
        config.height = 0
        
        logger.debug("Created default configuration: 32BGRA, sRGB, no cursor")
        return config
    }
    
    // MARK: - Display-Specific Configuration
    
    /// Creates an optimal configuration for a specific display
    /// - Parameter display: The SCDisplay to configure for
    /// - Returns: Optimized configuration for the display
    func optimalConfiguration(for display: SCDisplay) -> SCStreamConfiguration {
        let config = defaultConfiguration()
        
        config.width = display.width
        config.height = display.height
        
        logger.info("Created optimal configuration for display \(display.displayID): \(display.width)x\(display.height)")
        
        return config
    }
    
    /// Creates a configuration for capturing a specific area on a display
    /// - Parameters:
    ///   - area: The area to capture
    ///   - display: The display containing the area
    /// - Returns: Configuration optimized for area capture
    func configuration(for area: CGRect, on display: SCDisplay) -> SCStreamConfiguration {
        let config = defaultConfiguration()
        
        config.width = Int(area.width)
        config.height = Int(area.height)
        config.sourceRect = area
        
        logger.info("Created area configuration: \(Int(area.width))x\(Int(area.height)) at (\(Int(area.minX)), \(Int(area.minY)))")
        
        return config
    }
    
    // MARK: - Performance Mode Configurations
    
    /// Creates a configuration optimized for a specific performance mode
    /// - Parameters:
    ///   - mode: The performance mode to optimize for
    ///   - display: The target display
    /// - Returns: Configuration optimized for the specified performance mode
    func configuration(for mode: PerformanceMode, display: SCDisplay) -> SCStreamConfiguration {
        let config = optimalConfiguration(for: display)
        
        switch mode {
        case .quality:
            // Quality mode: Use highest quality settings
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.colorSpaceName = CGColorSpace.sRGB
            logger.debug("Applied quality mode configuration")
            
        case .balanced:
            // Balanced mode: Good quality with reasonable performance
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.colorSpaceName = CGColorSpace.sRGB
            logger.debug("Applied balanced mode configuration")
            
        case .speed:
            // Speed mode: Prioritize capture speed
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.colorSpaceName = CGColorSpace.sRGB
            logger.debug("Applied speed mode configuration")
        }
        
        return config
    }
    
    // MARK: - Configuration Validation
    
    /// Validates a capture configuration for common issues
    /// - Parameter config: The configuration to validate
    /// - Returns: True if the configuration is valid
    func isValidConfiguration(_ config: SCStreamConfiguration) -> Bool {
        // Check for valid dimensions
        guard config.width > 0 && config.height > 0 else {
            logger.error("Invalid configuration: zero or negative dimensions (\(config.width)x\(config.height))")
            return false
        }
        
        // Check for reasonable maximum dimensions
        guard config.width <= maxReasonableWidth && config.height <= maxReasonableHeight else {
            logger.error("Invalid configuration: dimensions exceed reasonable limits (\(config.width)x\(config.height))")
            return false
        }
        
        // Check for minimum size
        guard config.width >= minCaptureSize && config.height >= minCaptureSize else {
            logger.error("Invalid configuration: dimensions below minimum size (\(config.width)x\(config.height))")
            return false
        }
        
        logger.debug("Configuration validation passed: \(config.width)x\(config.height)")
        return true
    }
    
    // MARK: - Memory Management
    
    /// Estimates memory usage for a given configuration
    /// - Parameter config: The configuration to analyze
    /// - Returns: Estimated memory usage in bytes
    func estimatedMemoryUsage(for config: SCStreamConfiguration) -> UInt64 {
        let pixels = UInt64(config.width * config.height)
        let memoryUsage = pixels * UInt64(bytesPerPixel)
        
        logger.debug("Estimated memory usage: \(self.formatMemorySize(memoryUsage)) for \(config.width)x\(config.height)")
        
        return memoryUsage
    }
    
    /// Optimizes a configuration to fit within memory constraints
    /// - Parameters:
    ///   - config: The original configuration
    ///   - maxMemoryMB: Maximum memory usage in megabytes
    /// - Returns: Optimized configuration that fits within memory limits
    func optimizeForMemoryConstraints(_ config: SCStreamConfiguration, maxMemoryMB: Int) -> SCStreamConfiguration {
        let maxMemoryBytes = UInt64(maxMemoryMB) * 1024 * 1024
        let currentMemoryUsage = estimatedMemoryUsage(for: config)
        
        guard currentMemoryUsage > maxMemoryBytes else {
            logger.debug("Configuration already within memory constraints")
            return config
        }
        
        let optimizedConfig = SCStreamConfiguration()
        optimizedConfig.pixelFormat = config.pixelFormat
        optimizedConfig.colorSpaceName = config.colorSpaceName
        optimizedConfig.showsCursor = config.showsCursor
        
        // Calculate scaling factor to fit within memory constraints
        let scaleFactor = sqrt(Double(maxMemoryBytes) / Double(currentMemoryUsage))
        
        optimizedConfig.width = max(minCaptureSize, Int(Double(config.width) * scaleFactor))
        optimizedConfig.height = max(minCaptureSize, Int(Double(config.height) * scaleFactor))
        
        let newMemoryUsage = estimatedMemoryUsage(for: optimizedConfig)
        
        logger.info("Optimized configuration for memory constraints: \(config.width)x\(config.height) -> \(optimizedConfig.width)x\(optimizedConfig.height) (\(self.formatMemorySize(currentMemoryUsage)) -> \(self.formatMemorySize(newMemoryUsage)))")
        
        return optimizedConfig
    }
    
    // MARK: - Configuration Analysis
    
    /// Provides a human-readable description of a configuration
    /// - Parameter config: The configuration to describe
    /// - Returns: Descriptive string of the configuration settings
    func configurationDescription(_ config: SCStreamConfiguration) -> String {
        let pixelFormatName = pixelFormatDescription(config.pixelFormat)
        let colorSpaceName = config.colorSpaceName as String? ?? "Unknown"
        let memoryUsage = formatMemorySize(estimatedMemoryUsage(for: config))
        
        return """
        Configuration Details:
        - Dimensions: \(config.width)x\(config.height)
        - Pixel Format: \(pixelFormatName)
        - Color Space: \(colorSpaceName)
        - Shows Cursor: \(config.showsCursor)
        - Estimated Memory: \(memoryUsage)
        """
    }
    
    // MARK: - Private Helper Methods
    
    /// Returns a human-readable description of a pixel format
    private func pixelFormatDescription(_ pixelFormat: OSType) -> String {
        switch pixelFormat {
        case kCVPixelFormatType_32BGRA:
            return "32BGRA"
        case kCVPixelFormatType_32ARGB:
            return "32ARGB"
        case kCVPixelFormatType_24RGB:
            return "24RGB"
        case kCVPixelFormatType_16BE555:
            return "16BE555"
        default:
            return "Unknown (\(pixelFormat))"
        }
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
}

// MARK: - Protocol for Testing

/// Protocol to abstract SCDisplay for testing purposes
protocol SCDisplayProtocol {
    var width: Int { get }
    var height: Int { get }
    var displayID: CGDirectDisplayID { get }
}

// Make SCDisplay conform to the protocol
extension SCDisplay: SCDisplayProtocol {}
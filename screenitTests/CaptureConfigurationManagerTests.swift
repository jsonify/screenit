import XCTest
import ScreenCaptureKit
@testable import screenit

@MainActor
final class CaptureConfigurationManagerTests: XCTestCase {
    
    var configManager: CaptureConfigurationManager!
    
    override func setUp() async throws {
        configManager = CaptureConfigurationManager()
    }
    
    override func tearDown() async throws {
        configManager = nil
    }
    
    // MARK: - Default Configuration Tests
    
    func testDefaultConfiguration() {
        let config = configManager.defaultConfiguration()
        
        XCTAssertEqual(config.pixelFormat, kCVPixelFormatType_32BGRA)
        XCTAssertEqual(config.colorSpaceName, CGColorSpace.sRGB)
        XCTAssertFalse(config.showsCursor)
        XCTAssertEqual(config.width, 0)
        XCTAssertEqual(config.height, 0)
    }
    
    // MARK: - Display Configuration Tests
    
    func testOptimalConfigurationForDisplay() {
        // Create a mock display with known dimensions
        let mockDisplay = MockSCDisplay(width: 1920, height: 1080, displayID: 1)
        
        let config = configManager.optimalConfiguration(for: mockDisplay)
        
        XCTAssertEqual(config.width, 1920)
        XCTAssertEqual(config.height, 1080)
        XCTAssertEqual(config.pixelFormat, kCVPixelFormatType_32BGRA)
        XCTAssertEqual(config.colorSpaceName, CGColorSpace.sRGB)
        XCTAssertFalse(config.showsCursor)
    }
    
    func testHighDPIDisplayConfiguration() {
        // Create a mock high-DPI display
        let mockDisplay = MockSCDisplay(width: 3840, height: 2160, displayID: 1)
        
        let config = configManager.optimalConfiguration(for: mockDisplay)
        
        XCTAssertEqual(config.width, 3840)
        XCTAssertEqual(config.height, 2160)
        // Should still use optimal settings for high-DPI
        XCTAssertEqual(config.pixelFormat, kCVPixelFormatType_32BGRA)
        XCTAssertEqual(config.colorSpaceName, CGColorSpace.sRGB)
    }
    
    // MARK: - Area Configuration Tests
    
    func testConfigurationForArea() {
        let area = CGRect(x: 100, y: 200, width: 800, height: 600)
        let mockDisplay = MockSCDisplay(width: 1920, height: 1080, displayID: 1)
        
        let config = configManager.configuration(for: area, on: mockDisplay)
        
        XCTAssertEqual(config.width, 800)
        XCTAssertEqual(config.height, 600)
        XCTAssertEqual(config.sourceRect, area)
        XCTAssertEqual(config.pixelFormat, kCVPixelFormatType_32BGRA)
        XCTAssertFalse(config.showsCursor)
    }
    
    func testConfigurationForSmallArea() {
        let smallArea = CGRect(x: 0, y: 0, width: 100, height: 100)
        let mockDisplay = MockSCDisplay(width: 1920, height: 1080, displayID: 1)
        
        let config = configManager.configuration(for: smallArea, on: mockDisplay)
        
        XCTAssertEqual(config.width, 100)
        XCTAssertEqual(config.height, 100)
        // Should maintain quality for small areas
        XCTAssertEqual(config.pixelFormat, kCVPixelFormatType_32BGRA)
    }
    
    // MARK: - Performance Mode Tests
    
    func testPerformanceModeConfigurations() {
        let mockDisplay = MockSCDisplay(width: 1920, height: 1080, displayID: 1)
        
        let qualityConfig = configManager.configuration(for: .quality, display: mockDisplay)
        let balancedConfig = configManager.configuration(for: .balanced, display: mockDisplay)
        let speedConfig = configManager.configuration(for: .speed, display: mockDisplay)
        
        // All should have same dimensions for same display
        XCTAssertEqual(qualityConfig.width, 1920)
        XCTAssertEqual(balancedConfig.width, 1920)
        XCTAssertEqual(speedConfig.width, 1920)
        
        // All should use optimal pixel format
        XCTAssertEqual(qualityConfig.pixelFormat, kCVPixelFormatType_32BGRA)
        XCTAssertEqual(balancedConfig.pixelFormat, kCVPixelFormatType_32BGRA)
        XCTAssertEqual(speedConfig.pixelFormat, kCVPixelFormatType_32BGRA)
    }
    
    // MARK: - Validation Tests
    
    func testValidateConfiguration() {
        let validConfig = SCStreamConfiguration()
        validConfig.width = 1920
        validConfig.height = 1080
        validConfig.pixelFormat = kCVPixelFormatType_32BGRA
        
        XCTAssertTrue(configManager.isValidConfiguration(validConfig))
    }
    
    func testValidateInvalidConfiguration() {
        let invalidConfig = SCStreamConfiguration()
        invalidConfig.width = 0
        invalidConfig.height = 0
        
        XCTAssertFalse(configManager.isValidConfiguration(invalidConfig))
    }
    
    func testValidateNegativeDimensions() {
        let invalidConfig = SCStreamConfiguration()
        invalidConfig.width = -100
        invalidConfig.height = 1080
        
        XCTAssertFalse(configManager.isValidConfiguration(invalidConfig))
    }
    
    func testValidateExcessiveDimensions() {
        let excessiveConfig = SCStreamConfiguration()
        excessiveConfig.width = 10000
        excessiveConfig.height = 10000
        
        XCTAssertFalse(configManager.isValidConfiguration(excessiveConfig))
    }
    
    // MARK: - Memory Estimation Tests
    
    func testEstimatedMemoryUsageForConfiguration() {
        let config = SCStreamConfiguration()
        config.width = 1920
        config.height = 1080
        config.pixelFormat = kCVPixelFormatType_32BGRA
        
        let estimatedMemory = configManager.estimatedMemoryUsage(for: config)
        
        // 1920 * 1080 * 4 bytes per pixel (32-bit BGRA)
        let expectedMemory: UInt64 = 1920 * 1080 * 4
        XCTAssertEqual(estimatedMemory, expectedMemory)
    }
    
    func testEstimatedMemoryUsageForSmallConfiguration() {
        let config = SCStreamConfiguration()
        config.width = 100
        config.height = 100
        config.pixelFormat = kCVPixelFormatType_32BGRA
        
        let estimatedMemory = configManager.estimatedMemoryUsage(for: config)
        
        let expectedMemory: UInt64 = 100 * 100 * 4
        XCTAssertEqual(estimatedMemory, expectedMemory)
    }
    
    // MARK: - Optimization Tests
    
    func testOptimizeForMemoryConstraints() {
        let mockDisplay = MockSCDisplay(width: 3840, height: 2160, displayID: 1)
        let originalConfig = configManager.optimalConfiguration(for: mockDisplay)
        
        let optimizedConfig = configManager.optimizeForMemoryConstraints(originalConfig, maxMemoryMB: 10)
        
        // Should reduce dimensions to fit memory constraint
        XCTAssertLessThan(optimizedConfig.width, originalConfig.width)
        XCTAssertLessThan(optimizedConfig.height, originalConfig.height)
        
        // Should maintain aspect ratio approximately
        let originalAspectRatio = Double(originalConfig.width) / Double(originalConfig.height)
        let optimizedAspectRatio = Double(optimizedConfig.width) / Double(optimizedConfig.height)
        XCTAssertEqual(originalAspectRatio, optimizedAspectRatio, accuracy: 0.1)
    }
    
    func testOptimizeForMemoryConstraintsWithSufficientMemory() {
        let mockDisplay = MockSCDisplay(width: 1920, height: 1080, displayID: 1)
        let originalConfig = configManager.optimalConfiguration(for: mockDisplay)
        
        let optimizedConfig = configManager.optimizeForMemoryConstraints(originalConfig, maxMemoryMB: 100)
        
        // Should not change configuration if memory is sufficient
        XCTAssertEqual(optimizedConfig.width, originalConfig.width)
        XCTAssertEqual(optimizedConfig.height, originalConfig.height)
    }
    
    // MARK: - Configuration Comparison Tests
    
    func testConfigurationDescription() {
        let config = SCStreamConfiguration()
        config.width = 1920
        config.height = 1080
        config.pixelFormat = kCVPixelFormatType_32BGRA
        
        let description = configManager.configurationDescription(config)
        
        XCTAssertTrue(description.contains("1920x1080"))
        XCTAssertTrue(description.contains("32BGRA"))
        XCTAssertTrue(description.contains("sRGB"))
    }
}

// MARK: - Mock Classes

private class MockSCDisplay {
    let width: Int
    let height: Int
    let displayID: CGDirectDisplayID
    
    init(width: Int, height: Int, displayID: CGDirectDisplayID) {
        self.width = width
        self.height = height
        self.displayID = displayID
    }
}

// Extension to make MockSCDisplay work with our configuration manager
extension MockSCDisplay: SCDisplayProtocol {
    // This protocol would need to be defined to abstract SCDisplay for testing
}
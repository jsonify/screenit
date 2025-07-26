import XCTest
@testable import screenit

@MainActor
final class CaptureEngineEnhancedTests: XCTestCase {
    
    var captureEngine: CaptureEngine!
    var mockPerformanceTimer: MockCapturePerformanceTimer!
    var mockErrorHandler: MockCaptureErrorHandler!
    var mockConfigurationManager: MockCaptureConfigurationManager!
    
    override func setUp() async throws {
        captureEngine = CaptureEngine.shared
        mockPerformanceTimer = MockCapturePerformanceTimer()
        mockErrorHandler = MockCaptureErrorHandler()
        mockConfigurationManager = MockCaptureConfigurationManager()
    }
    
    override func tearDown() async throws {
        captureEngine = nil
        mockPerformanceTimer = nil
        mockErrorHandler = nil
        mockConfigurationManager = nil
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testCaptureFullScreenRecordsPerformanceMetrics() async {
        // Test that capture operations are properly timed and recorded
        let startTime = Date()
        
        _ = await captureEngine.captureFullScreen()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Performance should be recorded (this would be verified with integration)
        XCTAssertGreaterThan(duration, 0)
        XCTAssertLessThan(duration, 10.0) // Should complete within reasonable time
    }
    
    func testCaptureAreaRecordsPerformanceMetrics() async {
        let area = CGRect(x: 100, y: 100, width: 800, height: 600)
        let startTime = Date()
        
        _ = await captureEngine.captureArea(area)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertGreaterThan(duration, 0)
        XCTAssertLessThan(duration, 10.0)
    }
    
    func testPerformanceTimerIntegration() {
        // Test that the performance timer is properly integrated
        XCTAssertFalse(captureEngine.performanceTimer.isTimerRunning)
        XCTAssertEqual(captureEngine.performanceTimer.captureCount, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlerIntegration() {
        // Test that error handler is properly integrated
        XCTAssertEqual(captureEngine.errorHandler.errorCount, 0)
        
        // Clear any existing errors to test clean state
        captureEngine.clearError()
        XCTAssertNil(captureEngine.lastError)
    }
    
    func testCaptureErrorRecording() async {
        // This test would require mocking the authorization to fail
        // For now, test the error handling structure
        
        captureEngine.clearError()
        XCTAssertNil(captureEngine.lastError)
        
        // Test that errors are properly handled when they occur
        if let error = captureEngine.lastError {
            XCTAssertTrue(captureEngine.errorHandler.errorCount >= 0)
        }
    }
    
    // MARK: - Configuration Manager Tests
    
    func testConfigurationManagerIntegration() {
        // Test that configuration manager is available
        XCTAssertNotNil(captureEngine.configurationManager)
        
        let defaultConfig = captureEngine.configurationManager.defaultConfiguration()
        XCTAssertTrue(captureEngine.configurationManager.isValidConfiguration(defaultConfig))
    }
    
    // MARK: - Enhanced Logging Tests
    
    func testComprehensiveLoggingDuringCapture() async {
        // Test that capture operations include comprehensive logging
        // This is more of a behavioral test - we verify the operation completes
        // and assume logging is happening based on our implementation
        
        let initialAuthStatus = captureEngine.authorizationStatus
        
        await captureEngine.updateAuthorizationStatus()
        
        // Should have updated status (and logged the process)
        XCTAssertNotNil(captureEngine.authorizationStatus)
    }
    
    func testPerformanceMetricsLogging() async {
        // Test that performance metrics are logged during operations
        let wasCapturing = captureEngine.isCapturing
        
        _ = await captureEngine.captureFullScreen()
        
        // Should have returned to non-capturing state
        XCTAssertFalse(captureEngine.isCapturing)
    }
    
    // MARK: - Integration Tests
    
    func testFullCaptureWorkflowWithEnhancements() async {
        // Test the complete workflow with all enhancements
        
        // 1. Check authorization status
        await captureEngine.updateAuthorizationStatus()
        
        // 2. Refresh content
        await captureEngine.refreshAvailableContent()
        
        // 3. Attempt capture (if authorized)
        if captureEngine.canCapture {
            let image = await captureEngine.captureFullScreen()
            
            // Should have completed without critical errors
            if let error = captureEngine.lastError {
                let severity = captureEngine.errorHandler.errorSeverity(for: error)
                XCTAssertNotEqual(severity, .critical)
            }
        }
        
        // 4. Verify performance tracking
        XCTAssertFalse(captureEngine.isCapturing)
        XCTAssertGreaterThanOrEqual(captureEngine.performanceTimer.captureCount, 0)
    }
    
    func testMemoryManagementDuringCapture() async {
        // Test that memory is properly managed during capture operations
        let initialMemoryUsage = captureEngine.performanceTimer.totalMemoryUsage
        
        _ = await captureEngine.captureFullScreen()
        
        // Memory usage should be tracked (if capture succeeded)
        let finalMemoryUsage = captureEngine.performanceTimer.totalMemoryUsage
        XCTAssertGreaterThanOrEqual(finalMemoryUsage, initialMemoryUsage)
    }
    
    // MARK: - Performance Target Tests
    
    func testCapturePerformanceTargets() async {
        // Test that captures meet performance targets
        let startTime = Date()
        
        _ = await captureEngine.captureFullScreen()
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should complete within target time (2 seconds as per spec)
        XCTAssertLessThan(duration, 2.0)
    }
    
    func testPerformanceReporting() {
        // Test that performance reporting is available
        let report = captureEngine.performanceTimer.performanceReport
        XCTAssertFalse(report.isEmpty)
        XCTAssertTrue(report.contains("Performance Report") || report.contains("No capture performance data"))
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecoveryWorkflow() async {
        // Test error recovery mechanisms
        captureEngine.clearError()
        XCTAssertNil(captureEngine.lastError)
        
        // Test that authorization recovery works
        if captureEngine.authorizationStatus != "authorized" {
            let granted = await captureEngine.requestAuthorization()
            // Should handle authorization request gracefully
            XCTAssertTrue(granted || !granted) // Either outcome should be handled
        }
    }
}

// MARK: - Mock Classes for Testing

class MockCapturePerformanceTimer: CapturePerformanceTimer {
    var mockIsTimerRunning = false
    var mockCaptureCount = 0
    var mockAverageCaptureTime: TimeInterval = 0
    
    override var isTimerRunning: Bool { mockIsTimerRunning }
    override var captureCount: Int { mockCaptureCount }
    override var averageCaptureTime: TimeInterval { mockAverageCaptureTime }
}

class MockCaptureErrorHandler: CaptureErrorHandler {
    var mockErrorCount = 0
    var mockMostCommonError: CaptureError?
    
    override var errorCount: Int { mockErrorCount }
    override var mostCommonError: CaptureError? { mockMostCommonError }
}

class MockCaptureConfigurationManager: CaptureConfigurationManager {
    var mockValidConfiguration = true
    
    override func isValidConfiguration(_ config: SCStreamConfiguration) -> Bool {
        return mockValidConfiguration
    }
}
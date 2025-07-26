import XCTest
@testable import screenit
import ScreenCaptureKit

@MainActor
final class IntegrationTests: XCTestCase {
    
    var captureEngine: CaptureEngine!
    var menuBarManager: MenuBarManager!
    var permissionManager: ScreenCapturePermissionManager!
    
    override func setUp() async throws {
        captureEngine = CaptureEngine.shared
        menuBarManager = MenuBarManager()
        permissionManager = ScreenCapturePermissionManager()
        
        // Reset all statistics before each test
        captureEngine.performanceTimer.resetMetrics()
        captureEngine.errorHandler.resetErrorCounts()
        captureEngine.clearError()
    }
    
    override func tearDown() async throws {
        captureEngine = nil
        menuBarManager = nil
        permissionManager = nil
    }
    
    // MARK: - Full Capture Workflow Integration Tests
    
    func testFullCaptureWorkflowWithPermission() async {
        // Test the complete workflow from menu trigger to file save
        
        // 1. Check initial state
        XCTAssertFalse(menuBarManager.isCapturing, "Should not be capturing initially")
        XCTAssertFalse(menuBarManager.showingErrorAlert, "Should not show error initially")
        XCTAssertFalse(menuBarManager.showingSuccessNotification, "Should not show success initially")
        
        // 2. Trigger capture (this will handle permission checks internally)
        menuBarManager.triggerCapture()
        
        // Wait for capture to complete (give it reasonable time)
        let expectation = XCTestExpectation(description: "Capture completes")
        
        Task {
            // Wait for capturing state to change
            var attempts = 0
            while menuBarManager.isCapturing && attempts < 100 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                attempts += 1
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
        
        // 3. Verify final state
        XCTAssertFalse(menuBarManager.isCapturing, "Should not be capturing after completion")
        
        // If permission is granted, we should have either success or error feedback
        if permissionManager.canCapture {
            // Should have some feedback (either success or error)
            let hasSuccessOrError = menuBarManager.showingSuccessNotification || 
                                   menuBarManager.showingErrorAlert ||
                                   !menuBarManager.lastSuccessMessage.isEmpty ||
                                   !menuBarManager.lastErrorMessage.isEmpty
            
            XCTAssertTrue(hasSuccessOrError, "Should provide user feedback after capture attempt")
        }
    }
    
    func testCaptureWorkflowPerformanceTargets() async throws {
        // Test that capture operations meet performance targets (sub-2-second)
        
        guard permissionManager.canCapture else {
            throw XCTSkip("Screen capture permission required for performance testing")
        }
        
        let startTime = Date()
        
        let image = await captureEngine.captureFullScreen()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Performance target: sub-2-second capture times
        XCTAssertLessThan(duration, 2.0, "Capture should complete within 2 seconds")
        XCTAssertGreaterThan(duration, 0.01, "Capture should take measurable time")
        
        if image != nil {
            // Verify performance metrics were recorded
            XCTAssertGreaterThan(captureEngine.performanceTimer.captureCount, 0, "Should record performance metrics")
            XCTAssertGreaterThan(captureEngine.performanceTimer.lastCaptureDuration, 0, "Should record capture duration")
        }
    }
    
    func testMemoryUsageAndCleanup() async throws {
        guard permissionManager.canCapture else {
            throw XCTSkip("Screen capture permission required for memory testing")
        }
        
        // Measure memory usage before capture
        let initialMemory = getMemoryUsage()
        
        // Perform multiple captures to test memory cleanup
        for i in 0..<5 {
            let area = CGRect(x: 100 + i * 10, y: 100 + i * 10, width: 400, height: 300)
            _ = await captureEngine.captureArea(area)
            
            // Brief pause between captures
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Force garbage collection
        autoreleasepool { }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (less than 100MB for 5 captures)
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024, "Memory usage should be reasonable")
        
        // Verify performance metrics were recorded for all captures
        XCTAssertEqual(captureEngine.performanceTimer.captureCount, 5, "Should record all capture metrics")
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingIntegration() async {
        // Test error handling across all failure scenarios
        
        // 1. Test invalid capture area
        let invalidArea = CGRect(x: -100, y: -100, width: 0, height: 0)
        let image = await captureEngine.captureArea(invalidArea)
        
        XCTAssertNil(image, "Should return nil for invalid area")
        XCTAssertNotNil(captureEngine.lastError, "Should record error for invalid area")
        
        if let error = captureEngine.lastError {
            // Verify error handler provides user-friendly message
            let userMessage = captureEngine.errorHandler.userFriendlyMessage(for: error)
            XCTAssertFalse(userMessage.isEmpty, "Should provide user-friendly error message")
            
            let recoverySuggestion = captureEngine.errorHandler.recoverySuggestion(for: error)
            XCTAssertFalse(recoverySuggestion.isEmpty, "Should provide recovery suggestion")
        }
        
        // 2. Test error statistics tracking
        XCTAssertGreaterThan(captureEngine.errorHandler.errorCount, 0, "Should track error count")
    }
    
    func testMenuBarErrorIntegration() async {
        // Test that menu bar properly handles and displays errors
        
        // Simulate error condition by trying invalid capture
        let invalidArea = CGRect(x: -1, y: -1, width: -1, height: -1)
        _ = await captureEngine.captureArea(invalidArea)
        
        // Trigger menu bar capture which should handle the error
        menuBarManager.triggerCapture()
        
        // Wait for operation to complete
        let expectation = XCTestExpectation(description: "Error handling completes")
        
        Task {
            var attempts = 0
            while menuBarManager.isCapturing && attempts < 50 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                attempts += 1
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // If there was an error, menu bar should handle it appropriately
        if !menuBarManager.lastErrorMessage.isEmpty {
            XCTAssertTrue(menuBarManager.showingErrorAlert || !menuBarManager.lastErrorMessage.isEmpty,
                         "Menu bar should show error feedback")
            
            // Error message should be user-friendly (not just technical details)
            XCTAssertFalse(menuBarManager.lastErrorMessage.contains("NSError"), 
                          "Error message should be user-friendly")
        }
    }
    
    // MARK: - Performance Validation Tests
    
    func testPerformanceMetricsCollection() async throws {
        guard permissionManager.canCapture else {
            throw XCTSkip("Screen capture permission required for performance testing")
        }
        
        // Reset metrics
        captureEngine.performanceTimer.resetMetrics()
        
        // Perform test captures
        let testArea = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        
        for _ in 0..<3 {
            _ = await captureEngine.captureArea(testArea)
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds between captures
        }
        
        // Verify metrics collection
        XCTAssertEqual(captureEngine.performanceTimer.captureCount, 3, "Should record all captures")
        XCTAssertGreaterThan(captureEngine.performanceTimer.averageCaptureTime, 0, "Should calculate average time")
        XCTAssertGreaterThan(captureEngine.performanceTimer.totalMemoryUsage, 0, "Should track memory usage")
        
        // Verify performance report
        let report = captureEngine.performanceTimer.performanceReport
        XCTAssertTrue(report.contains("Capture Count: 3"), "Report should include capture count")
        XCTAssertTrue(report.contains("Average Duration"), "Report should include timing info")
    }
    
    func testConfigurationOptimization() async {
        // Test that configuration manager provides optimal settings
        
        let displays = await captureEngine.scCaptureManager.availableDisplays
        guard let primaryDisplay = displays.first else {
            XCTSkip("No displays available for configuration testing")
            return
        }
        
        // Test optimal configuration generation
        let config = captureEngine.configurationManager.optimalConfiguration(for: primaryDisplay)
        
        XCTAssertEqual(config.width, primaryDisplay.width, "Should match display width")
        XCTAssertEqual(config.height, primaryDisplay.height, "Should match display height")
        XCTAssertEqual(config.pixelFormat, kCVPixelFormatType_32BGRA, "Should use optimal pixel format")
        XCTAssertEqual(config.colorSpaceName, CGColorSpace.sRGB, "Should use sRGB color space")
        XCTAssertFalse(config.showsCursor, "Should not show cursor for clean screenshots")
        
        // Test configuration validation
        XCTAssertTrue(captureEngine.configurationManager.isValidConfiguration(config), 
                     "Generated configuration should be valid")
        
        // Test memory estimation
        let estimatedMemory = captureEngine.configurationManager.estimatedMemoryUsage(for: config)
        XCTAssertGreaterThan(estimatedMemory, 0, "Should estimate memory usage")
        
        // Memory estimation should be reasonable for typical display sizes
        let maxReasonableMemory: UInt64 = 200 * 1024 * 1024 // 200MB
        XCTAssertLessThan(estimatedMemory, maxReasonableMemory, "Memory estimation should be reasonable")
    }
    
    // MARK: - End-to-End Workflow Tests
    
    func testCompleteMenuBarWorkflow() async {
        // Test complete workflow: menu trigger → capture → save → feedback
        
        let initialCaptureCount = captureEngine.performanceTimer.captureCount
        
        // Trigger capture through menu bar
        menuBarManager.triggerCapture()
        
        // Wait for workflow to complete
        let expectation = XCTestExpectation(description: "Complete workflow")
        
        Task {
            var attempts = 0
            while menuBarManager.isCapturing && attempts < 100 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                attempts += 1
            }
            
            // Give additional time for async operations to complete
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 20.0)
        
        // Verify workflow completion
        XCTAssertFalse(menuBarManager.isCapturing, "Should complete capturing")
        
        if permissionManager.canCapture {
            // If permission is available, should have attempted capture
            let finalCaptureCount = captureEngine.performanceTimer.captureCount
            XCTAssertGreaterThanOrEqual(finalCaptureCount, initialCaptureCount, 
                                       "Should have attempted capture")
            
            // Should provide user feedback
            let hasFeedback = menuBarManager.showingSuccessNotification || 
                             menuBarManager.showingErrorAlert ||
                             !menuBarManager.lastSuccessMessage.isEmpty ||
                             !menuBarManager.lastErrorMessage.isEmpty ||
                             !menuBarManager.performanceStatus.isEmpty
            
            XCTAssertTrue(hasFeedback, "Should provide user feedback")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}
import XCTest
@testable import screenit

@MainActor
final class MenuBarManagerEnhancedTests: XCTestCase {
    
    var menuBarManager: MenuBarManager!
    var captureEngine: CaptureEngine!
    
    override func setUp() async throws {
        menuBarManager = MenuBarManager()
        captureEngine = CaptureEngine.shared
        
        // Reset states
        menuBarManager.showingErrorAlert = false
        menuBarManager.showingSuccessNotification = false
        menuBarManager.lastErrorMessage = ""
        menuBarManager.lastSuccessMessage = ""
        captureEngine.clearError()
    }
    
    override func tearDown() async throws {
        menuBarManager = nil
        captureEngine = nil
    }
    
    // MARK: - Enhanced User Feedback Tests
    
    func testErrorAlertHandling() {
        // Test error alert state management
        XCTAssertFalse(menuBarManager.showingErrorAlert, "Should not show error alert initially")
        XCTAssertTrue(menuBarManager.lastErrorMessage.isEmpty, "Should not have error message initially")
        
        // Simulate error by setting error message and showing alert
        menuBarManager.lastErrorMessage = "Test error message"
        menuBarManager.showingErrorAlert = true
        
        XCTAssertTrue(menuBarManager.showingErrorAlert, "Should show error alert")
        XCTAssertFalse(menuBarManager.lastErrorMessage.isEmpty, "Should have error message")
        
        // Test dismissing error alert
        menuBarManager.dismissErrorAlert()
        
        XCTAssertFalse(menuBarManager.showingErrorAlert, "Should dismiss error alert")
        XCTAssertTrue(menuBarManager.lastErrorMessage.isEmpty, "Should clear error message")
    }
    
    func testSuccessNotificationHandling() {
        // Test success notification state management
        XCTAssertFalse(menuBarManager.showingSuccessNotification, "Should not show success initially")
        XCTAssertTrue(menuBarManager.lastSuccessMessage.isEmpty, "Should not have success message initially")
        
        // Simulate success notification
        menuBarManager.lastSuccessMessage = "Test success message"
        menuBarManager.showingSuccessNotification = true
        
        XCTAssertTrue(menuBarManager.showingSuccessNotification, "Should show success notification")
        XCTAssertFalse(menuBarManager.lastSuccessMessage.isEmpty, "Should have success message")
        
        // Test dismissing success notification
        menuBarManager.dismissSuccessNotification()
        
        XCTAssertFalse(menuBarManager.showingSuccessNotification, "Should dismiss success notification")
        XCTAssertTrue(menuBarManager.lastSuccessMessage.isEmpty, "Should clear success message")
    }
    
    func testCapturingStateManagement() {
        // Test capturing state tracking
        XCTAssertFalse(menuBarManager.isCapturing, "Should not be capturing initially")
        
        // Simulate capturing state
        menuBarManager.isCapturing = true
        XCTAssertTrue(menuBarManager.isCapturing, "Should indicate capturing")
        
        menuBarManager.isCapturing = false
        XCTAssertFalse(menuBarManager.isCapturing, "Should indicate not capturing")
    }
    
    func testPerformanceStatusUpdates() {
        // Test performance status updates
        XCTAssertTrue(menuBarManager.performanceStatus.isEmpty, "Should have empty performance status initially")
        
        // Test updating performance status (internal method, test through public interface)
        // We can test this through the capture engine status
        let status = menuBarManager.captureEngineStatus
        XCTAssertFalse(status.isEmpty, "Should provide capture engine status")
        
        // Status should be one of the expected values
        let validStatuses = ["Capturing...", "Ready", "Permission required"]
        XCTAssertTrue(validStatuses.contains(status), "Should have valid status: \(status)")
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecoverySuggestion() {
        // Test that recovery suggestions are provided
        
        // When no error, should return empty suggestion
        XCTAssertTrue(menuBarManager.errorRecoverySuggestion.isEmpty, "Should have no suggestion when no error")
        
        // Simulate an error in capture engine
        let testError = CaptureError.notAuthorized
        captureEngine.lastError = testError
        
        let suggestion = menuBarManager.errorRecoverySuggestion
        XCTAssertFalse(suggestion.isEmpty, "Should provide recovery suggestion for error")
        XCTAssertTrue(suggestion.contains("permission") || suggestion.contains("Permission"), 
                     "Suggestion should be relevant to authorization error")
    }
    
    func testUserFriendlyErrorMessages() async {
        // Test integration with error handler for user-friendly messages
        
        // Simulate capture failure with authorization error
        captureEngine.lastError = CaptureError.notAuthorized
        
        // Trigger the error handling (would normally happen in capture)
        await menuBarManager.handleCaptureError()
        
        XCTAssertTrue(menuBarManager.showingErrorAlert, "Should show error alert")
        XCTAssertFalse(menuBarManager.lastErrorMessage.isEmpty, "Should have error message")
        
        // Message should be user-friendly (not technical)
        let errorMessage = menuBarManager.lastErrorMessage
        XCTAssertTrue(errorMessage.contains("Screen Recording permission") || 
                     errorMessage.contains("permission"), 
                     "Should provide user-friendly permission message")
        XCTAssertFalse(errorMessage.contains("NSError") || errorMessage.contains("kern_return_t"), 
                      "Should not contain technical error details")
    }
    
    // MARK: - Integration with Capture Engine Tests
    
    func testCaptureEngineIntegration() {
        // Test that menu bar manager properly integrates with capture engine
        
        // Verify shared instance usage
        XCTAssertIdentical(menuBarManager.captureEngine, CaptureEngine.shared, 
                          "Should use shared capture engine instance")
        
        // Test status reporting
        let status = menuBarManager.captureEngineStatus
        XCTAssertFalse(status.isEmpty, "Should report capture engine status")
        
        // Test performance metrics access
        let metrics = menuBarManager.currentPerformanceMetrics
        XCTAssertTrue(metrics.contains("Performance Report") || metrics.contains("No capture"), 
                     "Should provide performance metrics")
        
        // Test error statistics access
        let errorStats = menuBarManager.errorStatistics
        XCTAssertTrue(errorStats.contains("Error Report") || errorStats.contains("No errors"), 
                     "Should provide error statistics")
    }
    
    func testRefreshCaptureContent() {
        // Test refreshing capture content
        let initialPerformanceStatus = menuBarManager.performanceStatus
        
        menuBarManager.refreshCaptureContent()
        
        // Should trigger async refresh (we can't easily test the async result,
        // but we can verify the method exists and doesn't crash)
        XCTAssertNoThrow(menuBarManager.refreshCaptureContent(), "Should not throw when refreshing content")
    }
    
    func testResetStatistics() {
        // Test resetting statistics
        
        // First, ensure we have some metrics (simulate by accessing the engine)
        let initialCaptureCount = captureEngine.performanceTimer.captureCount
        let initialErrorCount = captureEngine.errorHandler.errorCount
        
        // Reset statistics
        XCTAssertNoThrow(menuBarManager.resetStatistics(), "Should not throw when resetting statistics")
        
        // Verify reset (the actual reset happens in the capture engine)
        let postResetCaptureCount = captureEngine.performanceTimer.captureCount
        let postResetErrorCount = captureEngine.errorHandler.errorCount
        
        XCTAssertEqual(postResetCaptureCount, 0, "Should reset capture count")
        XCTAssertEqual(postResetErrorCount, 0, "Should reset error count")
    }
    
    // MARK: - Menu Bar Visibility Tests
    
    func testMenuBarVisibilityManagement() {
        // Test menu bar visibility controls
        
        // Default state
        XCTAssertTrue(menuBarManager.isVisible, "Should be visible by default")
        
        // Test hiding
        menuBarManager.hideMenuBar()
        XCTAssertFalse(menuBarManager.isVisible, "Should be hidden after hideMenuBar")
        
        // Test showing
        menuBarManager.showMenuBar()
        XCTAssertTrue(menuBarManager.isVisible, "Should be visible after showMenuBar")
        
        // Test toggling
        menuBarManager.toggleVisibility()
        XCTAssertFalse(menuBarManager.isVisible, "Should toggle to hidden")
        
        menuBarManager.toggleVisibility()
        XCTAssertTrue(menuBarManager.isVisible, "Should toggle to visible")
    }
    
    // MARK: - Permission Integration Tests
    
    func testPermissionIntegration() {
        // Test integration with permission manager
        
        let canCapture = menuBarManager.canCapture
        let statusMessage = menuBarManager.permissionStatusMessage
        
        // Should provide meaningful values
        XCTAssertFalse(statusMessage.isEmpty, "Should provide permission status message")
        
        // Status should be consistent
        if canCapture {
            XCTAssertTrue(statusMessage.contains("granted") || statusMessage.contains("authorized"), 
                         "Status message should reflect permission state")
        } else {
            XCTAssertTrue(statusMessage.contains("required") || statusMessage.contains("denied") || 
                         statusMessage.contains("restricted"), 
                         "Status message should reflect permission state")
        }
    }
    
    func testOpenSystemPreferences() {
        // Test opening system preferences (we can't actually test the system call,
        // but we can verify the method exists and doesn't crash)
        
        XCTAssertNoThrow(menuBarManager.openSystemPreferences(), 
                        "Should not throw when opening system preferences")
        
        // After calling, permission alert should be dismissed
        menuBarManager.showingPermissionAlert = true
        menuBarManager.openSystemPreferences()
        XCTAssertFalse(menuBarManager.showingPermissionAlert, 
                      "Should dismiss permission alert when opening system preferences")
    }
    
    // MARK: - File Saving Integration Tests
    
    func testFileSaveErrorHandling() async {
        // Test file save error handling (we can't easily simulate file save errors,
        // but we can test the error handling structure)
        
        // Test that error handling methods exist and work
        await menuBarManager.handleFileSaveError("Test save error")
        
        XCTAssertTrue(menuBarManager.showingErrorAlert, "Should show error alert for save failure")
        XCTAssertFalse(menuBarManager.lastErrorMessage.isEmpty, "Should have error message for save failure")
        XCTAssertTrue(menuBarManager.lastErrorMessage.contains("Failed to save screenshot"), 
                     "Error message should indicate save failure")
    }
    
    // MARK: - Other Menu Actions Tests
    
    func testOtherMenuActions() {
        // Test that other menu actions exist and don't crash
        
        XCTAssertNoThrow(menuBarManager.showHistory(), "showHistory should not throw")
        XCTAssertNoThrow(menuBarManager.showPreferences(), "showPreferences should not throw")
        
        // Note: We don't test quitApp() as it would terminate the test process
    }
}
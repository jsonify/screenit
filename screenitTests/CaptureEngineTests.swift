//
//  CaptureEngineTests.swift
//  screenitTests
//
//  Created by Claude Code on 7/16/25.
//

import XCTest
import SwiftUI
@testable import screenit

final class CaptureEngineTests: XCTestCase {
    
    var captureEngine: CaptureEngine!
    
    @MainActor
    override func setUp() {
        super.setUp()
        captureEngine = CaptureEngine()
    }
    
    override func tearDown() {
        captureEngine = nil
        super.tearDown()
    }
    
    @MainActor
    func testCaptureEngineInitialization() {
        XCTAssertFalse(captureEngine.isCapturing)
        XCTAssertFalse(captureEngine.capturePermissionGranted)
        XCTAssertNil(captureEngine.permissionError)
    }
    
    @MainActor
    func testPermissionErrorTypes() {
        let permissionDeniedError = CapturePermissionError.permissionDenied
        XCTAssertEqual(permissionDeniedError.errorDescription, "Screen recording permission denied")
        XCTAssertEqual(permissionDeniedError.recoverySuggestion, "Please enable screen recording permission in System Settings > Privacy & Security > Screen Recording")
        
        let timeoutError = CapturePermissionError.timeout
        XCTAssertEqual(timeoutError.errorDescription, "Permission request timed out")
        XCTAssertEqual(timeoutError.recoverySuggestion, "Please try again or restart the application")
        
        let unavailableError = CapturePermissionError.unavailable
        XCTAssertEqual(unavailableError.errorDescription, "Screen capture unavailable")
        XCTAssertEqual(unavailableError.recoverySuggestion, "Screen capture is not available on this system")
        
        let systemError = CapturePermissionError.systemError(NSError(domain: "test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"]))
        XCTAssertEqual(systemError.errorDescription, "System error: Test error")
        XCTAssertEqual(systemError.recoverySuggestion, "Please try restarting the application or your Mac")
    }
    
    @MainActor
    func testTimeoutFunction() async {
        let expectation = expectation(description: "Timeout function should throw TimeoutError")
        
        do {
            _ = try await withTimeout(seconds: 0.1) {
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                return "Should timeout"
            }
            XCTFail("Should have thrown TimeoutError")
        } catch is TimeoutError {
            expectation.fulfill()
        } catch {
            XCTFail("Should have thrown TimeoutError, got \(error)")
        }
        
        await waitForExpectations(timeout: 1.0)
    }
    
    @MainActor
    func testTimeoutFunctionSuccess() async {
        do {
            let result = try await withTimeout(seconds: 0.2) {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                return "Success"
            }
            XCTAssertEqual(result, "Success")
        } catch {
            XCTFail("Should not have thrown error: \(error)")
        }
    }
    
    @MainActor
    func testGetDisplayInfo() {
        let displayInfo = captureEngine.getDisplayInfo()
        
        // Test that the method returns an array (may be empty if no permission)
        XCTAssertNotNil(displayInfo)
        
        // If displays are available, test the structure
        for display in displayInfo {
            XCTAssertFalse(display.id.isEmpty)
            XCTAssertTrue(display.name.contains("Display"))
            XCTAssertGreaterThanOrEqual(display.frame.width, 0)
            XCTAssertGreaterThanOrEqual(display.frame.height, 0)
        }
    }
    
    @MainActor
    func testGetAvailableDisplays() {
        let displays = captureEngine.getAvailableDisplays()
        
        // Test that the method returns an array
        XCTAssertNotNil(displays)
        
        // May be empty if no screen recording permission
        if !displays.isEmpty {
            XCTAssertGreaterThan(displays.count, 0)
        }
    }
    
    @MainActor
    func testCaptureStateManagement() {
        // Test initial state
        XCTAssertFalse(captureEngine.isCapturing)
        
        // Note: We can't easily test actual capture without screen recording permission
        // in a test environment, but we can test the state management logic
    }
    
    func testPermissionErrorEquality() {
        let error1 = CapturePermissionError.permissionDenied
        let error2 = CapturePermissionError.permissionDenied
        
        // Test that same error types are considered equal
        switch (error1, error2) {
        case (.permissionDenied, .permissionDenied):
            XCTAssertTrue(true) // Pass
        default:
            XCTFail("Error types should match")
        }
        
        let timeoutError1 = CapturePermissionError.timeout
        let timeoutError2 = CapturePermissionError.timeout
        
        switch (timeoutError1, timeoutError2) {
        case (.timeout, .timeout):
            XCTAssertTrue(true) // Pass
        default:
            XCTFail("Timeout error types should match")
        }
    }
    
    @MainActor
    func testPermissionCheckRetry() async {
        // Test that retryPermissionCheck calls checkAndRequestPermission
        // This is mainly testing that the method exists and doesn't crash
        await captureEngine.retryPermissionCheck()
        
        // The method should complete without throwing
        XCTAssertTrue(true)
    }
    
    @MainActor
    func testForceRefreshDisplays() async {
        // Test that forceRefreshDisplays calls updateAvailableContent
        // This is mainly testing that the method exists and doesn't crash
        await captureEngine.forceRefreshDisplays()
        
        // The method should complete without throwing
        XCTAssertTrue(true)
    }
}
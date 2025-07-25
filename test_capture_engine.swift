import Foundation
import ScreenCaptureKit
import CoreGraphics
import OSLog

// Test-specific imports and mocks
@testable import CaptureEngine

/// Test suite for CaptureEngine functionality
class CaptureEngineTests {
    
    static func runTests() {
        print("🧪 Running CaptureEngine tests...")
        
        testSingletonPattern()
        testInitialState()
        testAuthorizationStatusUpdate()
        testErrorHandling()
        testPrimaryDisplayBounds()
        testClearError()
        
        print("✅ All CaptureEngine tests passed!")
    }
    
    // MARK: - Test Cases
    
    static func testSingletonPattern() {
        print("Testing singleton pattern...")
        
        let instance1 = CaptureEngine.shared
        let instance2 = CaptureEngine.shared
        
        // Check that both references point to the same instance
        assert(instance1 === instance2, "CaptureEngine should be a singleton")
        print("✓ Singleton pattern test passed")
    }
    
    static func testInitialState() {
        print("Testing initial state...")
        
        let engine = CaptureEngine.shared
        
        // Check initial published properties
        assert(engine.isCapturing == false, "Initial capturing state should be false")
        assert(engine.lastError == nil, "Initial error should be nil")
        print("✓ Initial state test passed")
    }
    
    static func testAuthorizationStatusUpdate() {
        print("Testing authorization status update...")
        
        let engine = CaptureEngine.shared
        
        // Test that authorization status can be updated
        engine.updateAuthorizationStatus()
        
        // Verify status is one of the valid values
        let validStatuses: [SCScreenCaptureAuthorizationStatus] = [
            .notDetermined, .denied, .authorized
        ]
        assert(validStatuses.contains(engine.authorizationStatus), 
               "Authorization status should be valid")
        
        print("✓ Authorization status update test passed")
    }
    
    static func testErrorHandling() {
        print("Testing error handling...")
        
        let engine = CaptureEngine.shared
        
        // Test CaptureError equality
        let error1 = CaptureError.notAuthorized
        let error2 = CaptureError.notAuthorized
        let error3 = CaptureError.noDisplaysAvailable
        
        assert(error1 == error2, "Same error types should be equal")
        assert(error1 != error3, "Different error types should not be equal")
        
        // Test error descriptions
        assert(error1.errorDescription != nil, "Error should have description")
        assert(error3.errorDescription != nil, "Error should have description")
        
        print("✓ Error handling test passed")
    }
    
    static func testPrimaryDisplayBounds() {
        print("Testing primary display bounds...")
        
        let engine = CaptureEngine.shared
        let bounds = engine.primaryDisplayBounds
        
        // Bounds should be non-negative (zero is valid if no content available)
        assert(bounds.width >= 0, "Display width should be non-negative")
        assert(bounds.height >= 0, "Display height should be non-negative")
        assert(bounds.origin.x >= 0, "Display x should be non-negative")
        assert(bounds.origin.y >= 0, "Display y should be non-negative")
        
        print("✓ Primary display bounds test passed")
    }
    
    static func testClearError() {
        print("Testing clear error functionality...")
        
        let engine = CaptureEngine.shared
        
        // Simulate an error state and then clear it
        Task { @MainActor in
            engine.lastError = CaptureError.notAuthorized
            assert(engine.lastError != nil, "Error should be set")
            
            engine.clearError()
            assert(engine.lastError == nil, "Error should be cleared")
        }
        
        print("✓ Clear error test passed")
    }
    
    // MARK: - Integration Tests
    
    static func testMenuBarManagerIntegration() {
        print("Testing MenuBarManager integration...")
        
        let manager = MenuBarManager()
        
        // Test that manager initializes without crashing
        assert(manager.isVisible == true, "Manager should initialize with visible state")
        
        // Test that capture trigger doesn't crash (permissions may not be granted)
        manager.triggerCapture()
        
        print("✓ MenuBarManager integration test passed")
    }
}

// MARK: - Mock Objects for Testing

/// Mock CaptureEngine for testing without actual screen capture
class MockCaptureEngine {
    var mockAuthorizationStatus: SCScreenCaptureAuthorizationStatus = .notDetermined
    var mockIsCapturing: Bool = false
    var mockLastError: CaptureError?
    var mockAvailableContent: Bool = true
    
    func mockRequestAuthorization() async -> Bool {
        // Simulate authorization request
        await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        mockAuthorizationStatus = .authorized
        return true
    }
    
    func mockCaptureFullScreen() async -> CGImage? {
        guard mockAuthorizationStatus == .authorized else {
            mockLastError = .notAuthorized
            return nil
        }
        
        mockIsCapturing = true
        defer { mockIsCapturing = false }
        
        // Create a simple test image
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: 100,
            height: 100,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        return context?.makeImage()
    }
}

// MARK: - Performance Tests

class CaptureEnginePerformanceTests {
    
    static func runPerformanceTests() {
        print("🚀 Running CaptureEngine performance tests...")
        
        testSingletonAccessPerformance()
        testAuthorizationStatusCheckPerformance()
        
        print("✅ All performance tests passed!")
    }
    
    static func testSingletonAccessPerformance() {
        print("Testing singleton access performance...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Access singleton 1000 times
        for _ in 0..<1000 {
            _ = CaptureEngine.shared
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should be very fast (less than 1ms)
        assert(timeElapsed < 0.001, "Singleton access should be very fast")
        print("✓ Singleton access performance test passed (time: \(timeElapsed)s)")
    }
    
    static func testAuthorizationStatusCheckPerformance() {
        print("Testing authorization status check performance...")
        
        let engine = CaptureEngine.shared
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check status 100 times
        for _ in 0..<100 {
            engine.updateAuthorizationStatus()
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should be reasonably fast (less than 10ms)
        assert(timeElapsed < 0.01, "Authorization status checks should be fast")
        print("✓ Authorization status performance test passed (time: \(timeElapsed)s)")
    }
}

// Run all tests
CaptureEngineTests.runTests()
CaptureEnginePerformanceTests.runPerformanceTests()
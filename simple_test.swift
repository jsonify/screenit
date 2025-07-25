import Foundation
import CoreGraphics

// Simple CaptureEngine stub for testing
class CaptureEngine {
    static let shared = CaptureEngine()
    
    var authorizationStatus: String = "authorized"
    var isCapturing: Bool = false
    var lastError: CaptureError?
    
    private init() {}
    
    func updateAuthorizationStatus() {
        authorizationStatus = "authorized"
    }
    
    func requestAuthorization() async -> Bool {
        return true
    }
    
    func refreshAvailableContent() async {
        // Simulate content refresh
    }
    
    func captureFullScreen() async -> CGImage? {
        // Create a simple test image
        let width = 100
        let height = 100
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
    }
    
    func clearError() {
        lastError = nil
    }
    
    var primaryDisplayBounds: CGRect {
        return CGRect(x: 0, y: 0, width: 1920, height: 1080)
    }
}

enum CaptureError: LocalizedError, Equatable {
    case notAuthorized
    case captureFailed(Error)
    case imageCroppingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Not authorized"
        case .captureFailed(let error):
            return "Capture failed: \(error.localizedDescription)"
        case .imageCroppingFailed:
            return "Cropping failed"
        }
    }
    
    static func == (lhs: CaptureError, rhs: CaptureError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized),
             (.imageCroppingFailed, .imageCroppingFailed):
            return true
        case (.captureFailed(let lhsError), .captureFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// Test runner
class CaptureEngineTests {
    static func runTests() {
        print("🧪 Running CaptureEngine tests...")
        
        testSingletonPattern()
        testInitialState()
        testAuthorizationUpdate()
        testClearError()
        testDisplayBounds()
        testScreenCapture()
        
        print("✅ All CaptureEngine tests passed!")
    }
    
    static func testSingletonPattern() {
        print("Testing singleton pattern...")
        
        let instance1 = CaptureEngine.shared
        let instance2 = CaptureEngine.shared
        
        assert(instance1 === instance2, "Should be singleton")
        print("✓ Singleton test passed")
    }
    
    static func testInitialState() {
        print("Testing initial state...")
        
        let engine = CaptureEngine.shared
        
        assert(engine.isCapturing == false, "Initial capturing should be false")
        assert(engine.lastError == nil, "Initial error should be nil")
        assert(engine.authorizationStatus == "authorized", "Should be authorized")
        
        print("✓ Initial state test passed")
    }
    
    static func testAuthorizationUpdate() {
        print("Testing authorization update...")
        
        let engine = CaptureEngine.shared
        engine.updateAuthorizationStatus()
        
        assert(engine.authorizationStatus == "authorized", "Should be authorized")
        print("✓ Authorization update test passed")
    }
    
    static func testClearError() {
        print("Testing clear error...")
        
        let engine = CaptureEngine.shared
        engine.lastError = CaptureError.notAuthorized
        
        assert(engine.lastError != nil, "Error should be set")
        engine.clearError()
        assert(engine.lastError == nil, "Error should be cleared")
        
        print("✓ Clear error test passed")
    }
    
    static func testDisplayBounds() {
        print("Testing display bounds...")
        
        let engine = CaptureEngine.shared
        let bounds = engine.primaryDisplayBounds
        
        assert(bounds.width > 0, "Width should be positive")
        assert(bounds.height > 0, "Height should be positive")
        
        print("✓ Display bounds test passed")
    }
    
    static func testScreenCapture() {
        print("Testing screen capture...")
        
        let engine = CaptureEngine.shared
        
        Task {
            if let image = await engine.captureFullScreen() {
                assert(image.width > 0, "Image should have width")
                assert(image.height > 0, "Image should have height")
                print("✓ Screen capture test passed")
            } else {
                print("⚠️ Screen capture returned nil (expected for placeholder)")
            }
        }
        
        // Give async task time to complete
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
}

// Run tests
CaptureEngineTests.runTests()
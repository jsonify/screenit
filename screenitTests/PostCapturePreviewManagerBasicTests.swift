import XCTest
@testable import screenit

@MainActor
final class PostCapturePreviewManagerBasicTests: XCTestCase {
    
    var previewManager: PostCapturePreviewManager!
    var mockImage: CGImage!
    
    override func setUp() async throws {
        // Create a mock CGImage for testing
        mockImage = createMockCGImage()
        previewManager = PostCapturePreviewManager()
    }
    
    override func tearDown() async throws {
        previewManager?.cleanup()
        previewManager = nil
        mockImage = nil
    }
    
    // MARK: - Helper Methods
    
    private func createMockCGImage() -> CGImage {
        let width = 100
        let height = 100
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!
        
        // Fill with blue color for visibility in tests
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()!
    }
    
    // MARK: - Basic Tests
    
    func testInitialization() {
        XCTAssertNotNil(previewManager)
        XCTAssertFalse(previewManager.isVisible)
        XCTAssertNil(previewManager.previewWindow)
        XCTAssertEqual(previewManager.timeoutDuration, 6.0) // Default timeout
    }
    
    func testInitializationWithCustomTimeout() {
        let customManager = PostCapturePreviewManager(timeoutDuration: 10.0)
        XCTAssertEqual(customManager.timeoutDuration, 10.0)
    }
    
    func testCleanupClearsState() async {
        // Show preview first
        await previewManager.showPreview(
            image: mockImage,
            onAnnotate: { },
            onDismiss: { }
        )
        
        // Cleanup
        previewManager.cleanup()
        
        XCTAssertFalse(previewManager.isVisible)
        XCTAssertNil(previewManager.previewWindow)
    }
    
    func testCalculatePositionForMainScreen() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let previewSize = CGSize(width: 300, height: 220)
        
        let position = previewManager.calculatePreviewPosition(
            previewSize: previewSize,
            screenFrame: screenFrame
        )
        
        // Should be positioned 20 points from right and bottom edges
        let expectedX = screenFrame.maxX - previewSize.width - 20
        let expectedY = screenFrame.minY + 20
        
        XCTAssertEqual(position.x, expectedX, accuracy: 1.0)
        XCTAssertEqual(position.y, expectedY, accuracy: 1.0)
    }
}
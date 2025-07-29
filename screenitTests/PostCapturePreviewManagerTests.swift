import XCTest
import SwiftUI
@testable import screenit

@MainActor
class PostCapturePreviewManagerTests: XCTestCase {
    
    var previewManager: PostCapturePreviewManager!
    var mockImage: CGImage!
    
    override func setUp() async throws {
        try await super.setUp()
        previewManager = PostCapturePreviewManager()
        
        // Create a test CGImage
        mockImage = try createTestImage()
    }
    
    override func tearDown() async throws {
        await previewManager?.cleanup()
        previewManager = nil
        mockImage = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() throws -> CGImage {
        let width = 100
        let height = 100
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw TestError.imageCreationFailed
        }
        
        // Fill with blue color
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let image = context.makeImage() else {
            throw TestError.imageCreationFailed
        }
        
        return image
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(previewManager)
        XCTAssertFalse(previewManager.isShowing)
        XCTAssertNil(previewManager.currentImage)
        XCTAssertEqual(previewManager.timeoutDuration, 6.0) // Default timeout
        XCTAssertFalse(previewManager.isTimerActive)
    }
    
    func testInitializationWithCustomTimeout() {
        let customTimeout: TimeInterval = 10.0
        let customManager = PostCapturePreviewManager(timeoutDuration: customTimeout)
        
        XCTAssertEqual(customManager.timeoutDuration, customTimeout)
        XCTAssertFalse(customManager.isShowing)
        XCTAssertFalse(customManager.isTimerActive)
    }
    
    // MARK: - Window Lifecycle Tests
    
    func testShowPreview() async {
        let expectation = expectation(description: "Preview should show")
        
        previewManager.showPreview(
            image: mockImage,
            onAnnotate: {},
            onDismiss: {
                expectation.fulfill()
            }
        )
        
        XCTAssertTrue(previewManager.isShowing)
        XCTAssertNotNil(previewManager.currentImage)
        XCTAssertTrue(previewManager.isTimerActive)
        
        // Test auto-dismiss by waiting for timeout (shortened for testing)
        previewManager.timeoutDuration = 0.1
        previewManager.resetTimer()
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        XCTAssertFalse(previewManager.isShowing)
        XCTAssertFalse(previewManager.isTimerActive)
    }
    
    func testHidePreview() {
        previewManager.showPreview(
            image: mockImage,
            onAnnotate: {},
            onDismiss: {}
        )
        
        XCTAssertTrue(previewManager.isShowing)
        
        previewManager.hidePreview()
        
        XCTAssertFalse(previewManager.isShowing)
        XCTAssertFalse(previewManager.isTimerActive)
        XCTAssertNil(previewManager.currentImage)
    }
    
    func testCleanup() {
        previewManager.showPreview(
            image: mockImage,
            onAnnotate: {},
            onDismiss: {}
        )
        
        XCTAssertTrue(previewManager.isShowing)
        XCTAssertTrue(previewManager.isTimerActive)
        
        await previewManager.cleanup()
        
        XCTAssertFalse(previewManager.isShowing)
        XCTAssertFalse(previewManager.isTimerActive)
        XCTAssertNil(previewManager.currentImage)
    }
    
    // MARK: - Timer System Tests
    
    func testTimerActivation() {
        XCTAssertFalse(previewManager.isTimerActive)
        
        previewManager.showPreview(
            image: mockImage,
            onAnnotate: {},
            onDismiss: {}
        )
        
        XCTAssertTrue(previewManager.isTimerActive)
    }
    
    func testTimerReset() {
        previewManager.showPreview(
            image: mockImage,
            onAnnotate: {},
            onDismiss: {}
        )
        
        XCTAssertTrue(previewManager.isTimerActive)
        
        previewManager.resetTimer()
        
        XCTAssertTrue(previewManager.isTimerActive)
    }
    
    func testTimerStop() {
        previewManager.showPreview(
            image: mockImage,
            onAnnotate: {},
            onDismiss: {}
        )
        
        XCTAssertTrue(previewManager.isTimerActive)
        
        previewManager.stopTimer()
        
        XCTAssertFalse(previewManager.isTimerActive)
    }
    
    func testTimerCountdown() async {
        let expectation = expectation(description: "Timer should countdown")
        
        // Use a short timeout for testing
        previewManager.timeoutDuration = 0.2
        var countdownValues: [TimeInterval] = []
        
        previewManager.onTimerUpdate = { remainingTime in
            countdownValues.append(remainingTime)
        }
        
        previewManager.showPreview(
            image: mockImage,
            onAnnotate: {},
            onDismiss: {
                expectation.fulfill()
            }
        )
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Should have received multiple countdown updates
        XCTAssertGreaterThan(countdownValues.count, 1)
        
        // Values should be decreasing
        for i in 1..<countdownValues.count {
            XCTAssertLessThan(countdownValues[i], countdownValues[i-1])
        }
    }
    
    // MARK: - Screen Positioning Tests
    
    func testCalculatePreviewPosition() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.visibleFrame
        
        let position = previewManager.calculatePreviewPosition(for: screen)
        
        // Should be in bottom-right corner with proper margins
        let expectedX = screenFrame.maxX - PostCapturePreviewManager.previewSize.width - PostCapturePreviewManager.edgeMargin
        let expectedY = screenFrame.minY + PostCapturePreviewManager.edgeMargin
        
        XCTAssertEqual(position.x, expectedX, accuracy: 1.0)
        XCTAssertEqual(position.y, expectedY, accuracy: 1.0)
    }
    
    func testCalculatePositionWithConstraints() {
        // Create a mock small screen
        let smallScreenFrame = NSRect(x: 0, y: 0, width: 200, height: 150)
        
        let position = previewManager.calculateConstrainedPosition(
            desiredPosition: NSPoint(x: 180, y: 10),
            screenFrame: smallScreenFrame
        )
        
        // Position should be adjusted to fit within screen bounds
        XCTAssertGreaterThanOrEqual(position.x, smallScreenFrame.minX)
        XCTAssertLessThanOrEqual(position.x + PostCapturePreviewManager.previewSize.width, smallScreenFrame.maxX)
        XCTAssertGreaterThanOrEqual(position.y, smallScreenFrame.minY)
        XCTAssertLessThanOrEqual(position.y + PostCapturePreviewManager.previewSize.height, smallScreenFrame.maxY)
    }
    
    func testMultiMonitorSupport() {
        // Test with multiple screens if available
        if NSScreen.screens.count > 1 {
            let secondScreen = NSScreen.screens[1]
            let position = previewManager.calculatePreviewPosition(for: secondScreen)
            let screenFrame = secondScreen.visibleFrame
            
            // Should be positioned relative to the specified screen
            XCTAssertGreaterThanOrEqual(position.x, screenFrame.minX)
            XCTAssertLessThanOrEqual(position.x + PostCapturePreviewManager.previewSize.width, screenFrame.maxX)
        }
    }
    
    // MARK: - Action Handler Tests
    
    func testAnnotateAction() {
        let expectation = expectation(description: "Annotate callback should be called")
        
        previewManager.showPreview(
            image: mockImage,
            onAnnotate: {
                expectation.fulfill()
            },
            onDismiss: {}
        )
        
        previewManager.handleAnnotateAction()
        
        wait(for: [expectation], timeout: 1.0)
        
        // Preview should be hidden after annotate action
        XCTAssertFalse(previewManager.isShowing)
        XCTAssertFalse(previewManager.isTimerActive)
    }
    
    func testDismissAction() {
        let expectation = expectation(description: "Dismiss callback should be called")
        
        previewManager.showPreview(
            image: mockImage,
            onAnnotate: {},
            onDismiss: {
                expectation.fulfill()
            }
        )
        
        previewManager.handleDismissAction()
        
        wait(for: [expectation], timeout: 1.0)
        
        // Preview should be hidden after dismiss action
        XCTAssertFalse(previewManager.isShowing)
        XCTAssertFalse(previewManager.isTimerActive)
    }
    
    // MARK: - Edge Case Tests
    
    func testShowPreviewWhenAlreadyShowing() {
        // Show first preview
        previewManager.showPreview(
            image: mockImage,
            onAnnotate: {},
            onDismiss: {}
        )
        
        XCTAssertTrue(previewManager.isShowing)
        let firstImage = previewManager.currentImage
        
        // Create second test image
        let secondImage = try! createTestImage()
        
        // Show second preview - should replace first
        previewManager.showPreview(
            image: secondImage,
            onAnnotate: {},
            onDismiss: {}
        )
        
        XCTAssertTrue(previewManager.isShowing)
        XCTAssertNotEqual(previewManager.currentImage, firstImage)
    }
    
    func testActionWhenNotShowing() {
        XCTAssertFalse(previewManager.isShowing)
        
        // These should not crash when preview is not showing
        previewManager.handleAnnotateAction()
        previewManager.handleDismissAction()
        previewManager.stopTimer()
        previewManager.resetTimer()
        previewManager.hidePreview()
    }
}

// MARK: - Test Errors

enum TestError: Error {
    case imageCreationFailed
}
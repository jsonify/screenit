import XCTest
import CoreData
import AppKit
@testable import screenit

final class DataManagerTests: XCTestCase {
    
    var dataManager: DataManager!
    var testImage: NSImage!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager()
        
        // Create a simple test image
        testImage = NSImage(size: CGSize(width: 100, height: 100))
        testImage.lockFocus()
        NSColor.blue.setFill()
        NSRect(x: 0, y: 0, width: 100, height: 100).fill()
        testImage.unlockFocus()
    }
    
    override func tearDown() {
        dataManager = nil
        testImage = nil
        super.tearDown()
    }
    
    func testDataManagerInitialization() {
        XCTAssertNotNil(dataManager, "DataManager should initialize")
        XCTAssertEqual(dataManager.captureRetentionLimit, 10, "Default retention limit should be 10")
        XCTAssertFalse(dataManager.isLoading, "Should not be loading initially")
    }
    
    func testSaveCaptureWithoutAnnotations() {
        let expectation = XCTestExpectation(description: "Save capture without annotations")
        
        dataManager.saveCaptureWithAnnotations(testImage, annotations: []) { result in
            switch result {
            case .success(let captureItem):
                XCTAssertNotNil(captureItem.id, "Capture item should have ID")
                XCTAssertNotNil(captureItem.timestamp, "Capture item should have timestamp")
                XCTAssertEqual(captureItem.width, 100, "Width should match test image")
                XCTAssertEqual(captureItem.height, 100, "Height should match test image")
                XCTAssertNotNil(captureItem.imageData, "Should have image data")
                XCTAssertNotNil(captureItem.thumbnailData, "Should have thumbnail data")
                XCTAssertGreaterThan(captureItem.fileSize, 0, "File size should be greater than 0")
                
            case .failure(let error):
                XCTFail("Save should succeed: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testLoadRecentCaptures() {
        // First save a capture
        let saveExpectation = XCTestExpectation(description: "Save capture")
        
        dataManager.saveCaptureWithAnnotations(testImage, annotations: []) { _ in
            saveExpectation.fulfill()
        }
        
        wait(for: [saveExpectation], timeout: 10.0)
        
        // Load captures
        dataManager.loadRecentCaptures()
        
        XCTAssertGreaterThan(dataManager.recentCaptures.count, 0, "Should have recent captures")
    }
    
    func testCaptureRetentionLimit() {
        let originalLimit = dataManager.captureRetentionLimit
        dataManager.captureRetentionLimit = 2
        
        XCTAssertEqual(dataManager.captureRetentionLimit, 2, "Retention limit should be updated")
        
        // Restore original
        dataManager.captureRetentionLimit = originalLimit
    }
    
    func testCopyToClipboard() {
        // First save a capture
        let expectation = XCTestExpectation(description: "Save capture for clipboard test")
        
        dataManager.saveCaptureWithAnnotations(testImage, annotations: []) { result in
            switch result {
            case .success(let captureItem):
                // Test clipboard copy
                self.dataManager.copyToClipboard(captureItem)
                
                // Verify clipboard has content
                let pasteboard = NSPasteboard.general
                let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage]
                XCTAssertNotNil(images, "Clipboard should contain images")
                XCTAssertGreaterThan(images?.count ?? 0, 0, "Should have at least one image")
                
            case .failure(let error):
                XCTFail("Save should succeed: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}
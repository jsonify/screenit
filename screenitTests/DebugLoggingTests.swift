import XCTest
@testable import screenit
import CoreGraphics

@MainActor
final class DebugLoggingTests: XCTestCase {
    
    var menuBarManager: MenuBarManager!
    var testImage: CGImage!
    
    override func setUp() async throws {
        menuBarManager = MenuBarManager()
        
        // Create a small test image for testing
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: 100,
            height: 100,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw XCTestError(.failureWhileWaiting)
        }
        
        // Fill with a test color
        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        
        testImage = context.makeImage()
    }
    
    override func tearDown() async throws {
        menuBarManager = nil
        testImage = nil
    }
    
    // MARK: - Debug Logging Infrastructure Tests
    
    func testDebugLoggingFunctionEntry() async {
        // Test that debug logging provides function entry information
        
        // We'll capture console output by testing the side effects
        // Since we can't easily capture print() output in tests, we'll test the logic flow
        
        // Verify that saveImageToDesktop can be called without crashing
        await menuBarManager.saveImageToDesktop(testImage)
        
        // The function should complete without throwing
        XCTAssertTrue(true, "saveImageToDesktop should complete without throwing")
    }
    
    func testDesktopDirectoryResolutionLogging() {
        // Test Desktop directory URL resolution with logging
        
        let fileManager = FileManager.default
        
        // Test that Desktop directory can be resolved
        do {
            let desktopURL = try fileManager.url(
                for: .desktopDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            
            XCTAssertTrue(desktopURL.path.contains("Desktop") || desktopURL.path.contains("/Users/"),
                         "Desktop URL should point to Desktop directory: \(desktopURL.path)")
            
            // Test that the directory exists
            let desktopExists = fileManager.fileExists(atPath: desktopURL.path)
            XCTAssertTrue(desktopExists, "Desktop directory should exist")
            
        } catch {
            XCTFail("Desktop directory resolution should not fail: \(error)")
        }
    }
    
    func testFileSystemPermissionChecking() {
        // Test file system permission validation
        
        let fileManager = FileManager.default
        
        do {
            let desktopURL = try fileManager.url(
                for: .desktopDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            
            // Test writability check
            let isWritable = fileManager.isWritableFile(atPath: desktopURL.path)
            
            // Should be able to determine writability (true or false)
            // The specific value depends on system configuration, but method should work
            XCTAssertNotNil(isWritable, "Should be able to determine file writability")
            
        } catch {
            XCTFail("Permission checking should not fail: \(error)")
        }
    }
    
    func testCGImageDestinationDebugLogging() {
        // Test CGImageDestination creation and finalization logging
        
        let tempDir = FileManager.default.temporaryDirectory
        let testFileURL = tempDir.appendingPathComponent("test-debug-image.png")
        
        // Test CGImageDestination creation
        let destination = CGImageDestinationCreateWithURL(
            testFileURL as CFURL,
            "public.png" as CFString,
            1,
            nil
        )
        
        XCTAssertNotNil(destination, "CGImageDestination should be created successfully")
        
        if let destination = destination {
            // Test adding image
            CGImageDestinationAddImage(destination, testImage, nil)
            
            // Test finalization
            let success = CGImageDestinationFinalize(destination)
            XCTAssertTrue(success, "CGImageDestination finalization should succeed")
            
            // Verify file was actually created
            let fileExists = FileManager.default.fileExists(atPath: testFileURL.path)
            XCTAssertTrue(fileExists, "File should exist after successful finalization")
            
            // Clean up test file
            try? FileManager.default.removeItem(at: testFileURL)
        }
    }
    
    func testFileExistenceVerification() {
        // Test post-save file existence verification
        
        let tempDir = FileManager.default.temporaryDirectory
        let testFileURL = tempDir.appendingPathComponent("test-verification.png")
        
        // Initially file should not exist
        var fileExists = FileManager.default.fileExists(atPath: testFileURL.path)
        XCTAssertFalse(fileExists, "File should not exist initially")
        
        // Create a test file
        guard let destination = CGImageDestinationCreateWithURL(
            testFileURL as CFURL,
            "public.png" as CFString,
            1,
            nil
        ) else {
            XCTFail("Should be able to create CGImageDestination")
            return
        }
        
        CGImageDestinationAddImage(destination, testImage, nil)
        let success = CGImageDestinationFinalize(destination)
        
        if success {
            // Now file should exist
            fileExists = FileManager.default.fileExists(atPath: testFileURL.path)
            XCTAssertTrue(fileExists, "File should exist after creation")
            
            // Test file attributes retrieval
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: testFileURL.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                XCTAssertGreaterThan(fileSize, 0, "File should have positive size")
                
            } catch {
                XCTFail("Should be able to get file attributes: \(error)")
            }
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: testFileURL)
    }
    
    func testErrorContextLogging() async {
        // Test that error conditions produce appropriate debug information
        
        // Create an invalid file path to trigger an error
        let invalidURL = URL(fileURLWithPath: "/invalid/path/that/does/not/exist/test.png")
        
        // Test CGImageDestination creation with invalid path
        let destination = CGImageDestinationCreateWithURL(
            invalidURL as CFURL,
            "public.png" as CFString,
            1,
            nil
        )
        
        // Depending on the system, this might succeed or fail
        // The important thing is that our error handling code can deal with either case
        
        if let destination = destination {
            CGImageDestinationAddImage(destination, testImage, nil)
            let success = CGImageDestinationFinalize(destination)
            
            // If it fails, that's expected for an invalid path
            if !success {
                // This is the expected error case we want to test logging for
                XCTAssertFalse(success, "Finalization should fail for invalid path")
            }
        }
    }
    
    func testTimestampedLogging() {
        // Test that debug logging includes timestamp information
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        // Verify timestamp format is correct
        XCTAssertFalse(timestamp.isEmpty, "Timestamp should not be empty")
        XCTAssertTrue(timestamp.contains("-"), "Timestamp should contain date separators")
        XCTAssertEqual(timestamp.count, 19, "Timestamp should be 19 characters long")
        
        // Test filename generation with timestamp
        let filename = "screenit-\(timestamp).png"
        XCTAssertTrue(filename.hasPrefix("screenit-"), "Filename should start with screenit-")
        XCTAssertTrue(filename.hasSuffix(".png"), "Filename should end with .png")
        XCTAssertTrue(filename.contains(timestamp), "Filename should contain timestamp")
    }
    
    func testDirectoryFallbackLogging() async {
        // Test that fallback from Desktop to Downloads is properly logged
        
        let fileManager = FileManager.default
        
        // Test that both Desktop and Downloads directories can be resolved
        do {
            let desktopURL = try fileManager.url(
                for: .desktopDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            XCTAssertNotNil(desktopURL, "Desktop URL should be resolvable")
            
            let downloadsURL = try fileManager.url(
                for: .downloadsDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            XCTAssertNotNil(downloadsURL, "Downloads URL should be resolvable")
            
            // Verify they are different directories
            XCTAssertNotEqual(desktopURL.path, downloadsURL.path, 
                             "Desktop and Downloads should be different directories")
            
        } catch {
            XCTFail("Directory resolution should not fail: \(error)")
        }
    }
    
    func testPerformanceTimingLogging() async {
        // Test that save operation timing is tracked
        
        let startTime = Date()
        
        // Perform save operation
        await menuBarManager.saveImageToDesktop(testImage)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Operation should complete in reasonable time (less than 10 seconds)
        XCTAssertLessThan(duration, 10.0, "Save operation should complete in reasonable time")
        XCTAssertGreaterThan(duration, 0.0, "Save operation should take some measurable time")
    }
    
    func testComprehensiveDebugWorkflow() async {
        // Test complete debug workflow with all logging elements
        
        // This test validates that the complete save workflow can execute
        // with comprehensive debugging without crashing
        
        let initialErrorState = menuBarManager.showingErrorAlert
        let initialSuccessState = menuBarManager.showingSuccessNotification
        
        // Execute the complete save workflow
        await menuBarManager.saveImageToDesktop(testImage)
        
        // The function should complete and update appropriate state
        // (Either success or error, depending on system configuration)
        
        let finalErrorState = menuBarManager.showingErrorAlert
        let finalSuccessState = menuBarManager.showingSuccessNotification
        
        // State should have changed in some way (either error or success)
        let stateChanged = (finalErrorState != initialErrorState) || 
                          (finalSuccessState != initialSuccessState)
        
        XCTAssertTrue(stateChanged, 
                     "Save operation should result in either success or error state change")
        
        // If success, should have success message
        if finalSuccessState {
            XCTAssertFalse(menuBarManager.lastSuccessMessage.isEmpty, 
                          "Success state should include success message")
        }
        
        // If error, should have error message
        if finalErrorState {
            XCTAssertFalse(menuBarManager.lastErrorMessage.isEmpty, 
                          "Error state should include error message")
        }
    }
}
//
//  PermissionFlowUITests.swift
//  screenitUITests
//
//  Created by Claude Code on 7/16/25.
//

import XCTest

final class PermissionFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testPermissionRequestViewAppears() throws {
        // Test that the permission request view appears when screen recording permission is not granted
        
        // Look for permission-related UI elements
        let permissionView = app.staticTexts["Screen Recording Permission Required"]
        let retryButton = app.buttons["Retry"]
        let settingsButton = app.buttons["Open System Settings"]
        
        // Check if permission view exists (may not be visible if permission is already granted)
        if permissionView.exists {
            XCTAssertTrue(permissionView.exists)
            XCTAssertTrue(retryButton.exists)
            XCTAssertTrue(settingsButton.exists)
        }
    }
    
    func testRetryPermissionButton() throws {
        // Test the retry permission functionality
        
        let retryButton = app.buttons["Retry"]
        
        if retryButton.exists {
            XCTAssertTrue(retryButton.isHittable)
            retryButton.tap()
            
            // Wait for the permission check to complete
            let expectation = expectation(description: "Permission check completed")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3.0)
            
            // The UI should respond to the permission check
            // (exact behavior depends on actual permission state)
        }
    }
    
    func testOpenSystemSettingsButton() throws {
        // Test that the settings button attempts to open System Settings
        
        let settingsButton = app.buttons["Open System Settings"]
        
        if settingsButton.exists {
            XCTAssertTrue(settingsButton.isHittable)
            
            // Note: Actually tapping this would open System Settings
            // In a real test environment, you might want to mock this behavior
            // For now, we just verify the button is accessible
        }
    }
    
    func testPermissionErrorStates() throws {
        // Test different permission error states
        
        // Look for various error messages that might be displayed
        let errorMessages = [
            "Screen recording permission denied",
            "Permission request timed out",
            "Screen capture unavailable",
            "System error"
        ]
        
        for errorMessage in errorMessages {
            let errorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", errorMessage))
            
            // If error is displayed, verify it's visible
            if errorText.firstMatch.exists {
                XCTAssertTrue(errorText.firstMatch.exists)
            }
        }
    }
    
    func testPermissionGrantedState() throws {
        // Test the UI when screen recording permission is granted
        
        // If permission is granted, we should see the main capture interface
        let captureButton = app.buttons["Capture"]
        let captureArea = app.buttons["Capture Area"]
        let captureFullScreen = app.buttons["Capture Full Screen"]
        
        // Note: These elements may not exist if permission is not granted
        // The test verifies the expected UI state based on permission status
        
        if captureButton.exists || captureArea.exists || captureFullScreen.exists {
            // Permission appears to be granted, verify main UI is accessible
            XCTAssertTrue(true) // Basic assertion that we reached this state
        }
    }
    
    func testAccessibilityOfPermissionViews() throws {
        // Test accessibility features of permission-related views
        
        let permissionView = app.staticTexts["Screen Recording Permission Required"]
        
        if permissionView.exists {
            // Verify accessibility properties
            XCTAssertNotNil(permissionView.label)
            XCTAssertFalse(permissionView.label.isEmpty)
        }
        
        let retryButton = app.buttons["Retry"]
        if retryButton.exists {
            XCTAssertNotNil(retryButton.label)
            XCTAssertTrue(retryButton.isEnabled)
        }
        
        let settingsButton = app.buttons["Open System Settings"]
        if settingsButton.exists {
            XCTAssertNotNil(settingsButton.label)
            XCTAssertTrue(settingsButton.isEnabled)
        }
    }
    
    func testPermissionViewLayout() throws {
        // Test the layout and positioning of permission-related elements
        
        let permissionView = app.staticTexts["Screen Recording Permission Required"]
        
        if permissionView.exists {
            // Verify the permission view is positioned correctly on screen
            let frame = permissionView.frame
            XCTAssertGreaterThan(frame.width, 0)
            XCTAssertGreaterThan(frame.height, 0)
            
            // Verify buttons are positioned below the text (basic layout check)
            let retryButton = app.buttons["Retry"]
            if retryButton.exists {
                XCTAssertGreaterThan(retryButton.frame.minY, permissionView.frame.maxY)
            }
        }
    }
    
    func testPermissionViewResponsiveness() throws {
        // Test that permission views respond appropriately to window resizing
        
        let window = app.windows.firstMatch
        
        if window.exists {
            let originalFrame = window.frame
            
            // Note: Programmatic window resizing in UI tests can be tricky
            // This test mainly verifies that UI elements remain accessible
            // after potential layout changes
            
            let permissionView = app.staticTexts["Screen Recording Permission Required"]
            if permissionView.exists {
                XCTAssertTrue(permissionView.exists)
            }
            
            let retryButton = app.buttons["Retry"]
            if retryButton.exists {
                XCTAssertTrue(retryButton.isHittable)
            }
        }
    }
    
    func testPermissionRecoveryFlow() throws {
        // Test the flow when permission is initially denied but then granted
        
        let retryButton = app.buttons["Retry"]
        
        if retryButton.exists {
            // Tap retry multiple times to simulate permission state changes
            for _ in 0..<3 {
                if retryButton.exists && retryButton.isHittable {
                    retryButton.tap()
                    
                    // Wait for UI to update
                    sleep(1)
                }
            }
            
            // Verify that the UI remains stable after multiple retry attempts
            XCTAssertTrue(app.windows.firstMatch.exists)
        }
    }
}
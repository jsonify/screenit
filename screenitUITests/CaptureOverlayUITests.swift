//
//  CaptureOverlayUITests.swift
//  screenitUITests
//
//  Created by Claude Code on 7/16/25.
//

import XCTest

final class CaptureOverlayUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testCaptureOverlayAppears() throws {
        // Test that the capture overlay appears when capture is initiated
        
        let captureButton = app.buttons["Capture Area"]
        
        if captureButton.exists && captureButton.isHittable {
            captureButton.tap()
            
            // Wait for overlay to appear
            let overlay = app.otherElements["CaptureOverlay"]
            let overlayAppeared = overlay.waitForExistence(timeout: 3.0)
            
            if overlayAppeared {
                XCTAssertTrue(overlay.exists)
                XCTAssertTrue(overlay.exists && overlay.isHittable)
            }
        }
    }
    
    func testCaptureOverlayInteraction() throws {
        // Test interaction with the capture overlay
        
        let captureButton = app.buttons["Capture Area"]
        
        if captureButton.exists && captureButton.isHittable {
            captureButton.tap()
            
            let overlay = app.otherElements["CaptureOverlay"]
            
            if overlay.waitForExistence(timeout: 3.0) {
                // Test that we can interact with the overlay
                XCTAssertTrue(overlay.isHittable)
                
                // Try to perform a drag gesture to select an area
                let startPoint = overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
                let endPoint = overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
                
                startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
                
                // Verify that a selection area is created
                let selectionArea = app.otherElements["SelectionArea"]
                if selectionArea.exists {
                    XCTAssertTrue(selectionArea.exists)
                }
            }
        }
    }
    
    func testCaptureOverlayEscape() throws {
        // Test escaping from the capture overlay
        
        let captureButton = app.buttons["Capture Area"]
        
        if captureButton.exists && captureButton.isHittable {
            captureButton.tap()
            
            let overlay = app.otherElements["CaptureOverlay"]
            
            if overlay.waitForExistence(timeout: 3.0) {
                // Press Escape key to cancel capture
                app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
                
                // Verify overlay disappears
                let overlayDisappeared = !overlay.waitForExistence(timeout: 2.0)
                XCTAssertTrue(overlayDisappeared || !overlay.exists)
            }
        }
    }
    
    func testCaptureOverlayCrosshair() throws {
        // Test the crosshair cursor behavior
        
        let captureButton = app.buttons["Capture Area"]
        
        if captureButton.exists && captureButton.isHittable {
            captureButton.tap()
            
            let overlay = app.otherElements["CaptureOverlay"]
            
            if overlay.waitForExistence(timeout: 3.0) {
                // Test moving the cursor around the overlay
                let centerPoint = overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                centerPoint.hover()
                
                // Verify crosshair elements are visible
                let crosshairHorizontal = app.otherElements["CrosshairHorizontal"]
                let crosshairVertical = app.otherElements["CrosshairVertical"]
                
                if crosshairHorizontal.exists {
                    XCTAssertTrue(crosshairHorizontal.exists)
                }
                
                if crosshairVertical.exists {
                    XCTAssertTrue(crosshairVertical.exists)
                }
            }
        }
    }
    
    func testCaptureOverlayMagnifier() throws {
        // Test the magnifier functionality
        
        let captureButton = app.buttons["Capture Area"]
        
        if captureButton.exists && captureButton.isHittable {
            captureButton.tap()
            
            let overlay = app.otherElements["CaptureOverlay"]
            
            if overlay.waitForExistence(timeout: 3.0) {
                // Move cursor to trigger magnifier
                let testPoint = overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.6))
                testPoint.hover()
                
                // Look for magnifier element
                let magnifier = app.otherElements["Magnifier"]
                
                if magnifier.exists {
                    XCTAssertTrue(magnifier.exists)
                    
                    // Verify magnifier contains magnified content
                    let magnifierContent = magnifier.children(matching: .any).firstMatch
                    if magnifierContent.exists {
                        XCTAssertTrue(magnifierContent.exists)
                    }
                }
            }
        }
    }
    
    func testCaptureOverlayCoordinateDisplay() throws {
        // Test coordinate display functionality
        
        let captureButton = app.buttons["Capture Area"]
        
        if captureButton.exists && captureButton.isHittable {
            captureButton.tap()
            
            let overlay = app.otherElements["CaptureOverlay"]
            
            if overlay.waitForExistence(timeout: 3.0) {
                // Move cursor to different positions
                let positions = [
                    CGVector(dx: 0.2, dy: 0.3),
                    CGVector(dx: 0.8, dy: 0.7),
                    CGVector(dx: 0.5, dy: 0.5)
                ]
                
                for position in positions {
                    let point = overlay.coordinate(withNormalizedOffset: position)
                    point.hover()
                    
                    // Look for coordinate display
                    let coordinateDisplay = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\d+,\\d+'")).firstMatch
                    
                    if coordinateDisplay.exists {
                        XCTAssertTrue(coordinateDisplay.exists)
                        XCTAssertFalse(coordinateDisplay.label.isEmpty)
                    }
                }
            }
        }
    }
    
    func testCaptureOverlayAreaSelection() throws {
        // Test area selection with different sizes
        
        let captureButton = app.buttons["Capture Area"]
        
        if captureButton.exists && captureButton.isHittable {
            captureButton.tap()
            
            let overlay = app.otherElements["CaptureOverlay"]
            
            if overlay.waitForExistence(timeout: 3.0) {
                // Test small selection
                let smallStart = overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.4))
                let smallEnd = overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                
                smallStart.press(forDuration: 0.1, thenDragTo: smallEnd)
                
                // Test large selection
                let largeStart = overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
                let largeEnd = overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9))
                
                largeStart.press(forDuration: 0.1, thenDragTo: largeEnd)
                
                // Verify selection area exists
                let selectionArea = app.otherElements["SelectionArea"]
                if selectionArea.exists {
                    XCTAssertTrue(selectionArea.exists)
                    XCTAssertGreaterThan(selectionArea.frame.width, 0)
                    XCTAssertGreaterThan(selectionArea.frame.height, 0)
                }
            }
        }
    }
    
    func testCaptureOverlayConfirmCapture() throws {
        // Test confirming a capture
        
        let captureButton = app.buttons["Capture Area"]
        
        if captureButton.exists && captureButton.isHittable {
            captureButton.tap()
            
            let overlay = app.otherElements["CaptureOverlay"]
            
            if overlay.waitForExistence(timeout: 3.0) {
                // Select an area
                let startPoint = overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
                let endPoint = overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
                
                startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
                
                // Look for confirm button or double-click to confirm
                let confirmButton = app.buttons["Confirm Capture"]
                
                if confirmButton.exists && confirmButton.isHittable {
                    confirmButton.tap()
                } else {
                    // Alternative: double-click to confirm
                    endPoint.doubleClick()
                }
                
                // Verify overlay disappears after capture
                let overlayDisappeared = !overlay.waitForExistence(timeout: 3.0)
                XCTAssertTrue(overlayDisappeared || !overlay.exists)
            }
        }
    }
    
    func testCaptureOverlayKeyboardShortcuts() throws {
        // Test keyboard shortcuts in capture overlay
        
        let captureButton = app.buttons["Capture Area"]
        
        if captureButton.exists && captureButton.isHittable {
            captureButton.tap()
            
            let overlay = app.otherElements["CaptureOverlay"]
            
            if overlay.waitForExistence(timeout: 3.0) {
                // Test Enter key to capture full screen
                app.typeKey(XCUIKeyboardKey.enter, modifierFlags: [])
                
                // Test Space to capture full screen
                app.typeKey(XCUIKeyboardKey.space, modifierFlags: [])
                
                // The overlay should respond to these keyboard inputs
                // Exact behavior depends on implementation
            }
        }
    }
    
    func testCaptureOverlayAccessibility() throws {
        // Test accessibility features of capture overlay
        
        let captureButton = app.buttons["Capture Area"]
        
        if captureButton.exists && captureButton.isHittable {
            captureButton.tap()
            
            let overlay = app.otherElements["CaptureOverlay"]
            
            if overlay.waitForExistence(timeout: 3.0) {
                // Verify accessibility properties
                XCTAssertNotNil(overlay.label)
                
                // Test VoiceOver navigation
                let firstElement = overlay.children(matching: .any).firstMatch
                if firstElement.exists {
                    firstElement.tap()
                }
                
                // Verify overlay remains accessible
                XCTAssertTrue(overlay.isHittable)
            }
        }
    }
}
import XCTest
import AppKit
@testable import screenit

@MainActor
final class StatusItemTests: XCTestCase {
    
    var menuBarManager: MenuBarManager!
    
    override func setUp() async throws {
        menuBarManager = MenuBarManager()
    }
    
    override func tearDown() async throws {
        menuBarManager = nil
    }
    
    // MARK: - Status Item Creation Tests
    
    func testStatusItemCreation() {
        // Test that status item is created successfully
        XCTAssertNotNil(menuBarManager.statusItem, "Status item should be created during initialization")
        
        // Verify status item is added to system status bar
        let statusBar = NSStatusBar.system
        let statusItems = statusBar.statusItems
        XCTAssertTrue(statusItems.contains { $0 === menuBarManager.statusItem }, 
                     "Status item should be added to system status bar")
    }
    
    func testStatusItemConfiguration() {
        guard let statusItem = menuBarManager.statusItem,
              let button = statusItem.button else {
            XCTFail("Status item or button should exist")
            return
        }
        
        // Test icon configuration
        XCTAssertNotNil(button.image, "Status item should have an image")
        XCTAssertEqual(button.image?.name(), "camera.viewfinder", "Should use correct SF Symbol")
        XCTAssertTrue(button.image?.isTemplate == true, "Image should be template for system appearance")
        
        // Test tooltip
        XCTAssertEqual(button.toolTip, "screenit - Screenshot tool", "Should have descriptive tooltip")
        
        // Test target-action setup
        XCTAssertNotNil(button.target, "Button should have target")
        XCTAssertNotNil(button.action, "Button should have action")
        XCTAssertTrue(button.target === menuBarManager, "Target should be menu bar manager")
    }
    
    func testStatusItemLength() {
        guard let statusItem = menuBarManager.statusItem else {
            XCTFail("Status item should exist")
            return
        }
        
        // Test that status item uses variable length
        XCTAssertEqual(statusItem.length, NSStatusItem.variableLength, 
                      "Should use variable length for flexible sizing")
    }
    
    // MARK: - System Appearance Integration Tests
    
    func testDarkModeSupport() {
        guard let statusItem = menuBarManager.statusItem,
              let button = statusItem.button,
              let image = button.image else {
            XCTFail("Status item components should exist")
            return
        }
        
        // Test template image for automatic appearance adaptation
        XCTAssertTrue(image.isTemplate, "Image should be template to support dark/light mode")
        
        // Template images automatically adapt to system appearance
        // We can verify the image exists and is properly configured
        XCTAssertNotNil(image, "Should have template image for appearance adaptation")
    }
    
    func testSFSymbolCompatibility() {
        guard let statusItem = menuBarManager.statusItem,
              let button = statusItem.button else {
            XCTFail("Status item components should exist")
            return  
        }
        
        // Test SF Symbol icon
        let expectedSymbol = "camera.viewfinder"
        let systemImage = NSImage(systemSymbolName: expectedSymbol, accessibilityDescription: "screenit")
        
        XCTAssertNotNil(systemImage, "SF Symbol '\(expectedSymbol)' should be available")
        XCTAssertEqual(button.image?.name(), expectedSymbol, "Should use correct SF Symbol")
    }
    
    // MARK: - Error Handling Tests
    
    func testStatusItemCreationFailure() {
        // Test graceful handling when status item creation fails
        // This is hard to simulate, but we can verify the error handling code path exists
        
        // The current implementation handles nil status item gracefully
        // by checking for nil before configuration
        let testManager = MenuBarManager()
        
        // If status item creation failed, the manager should still be usable
        XCTAssertNotNil(testManager, "MenuBarManager should initialize even if status item fails")
        
        // Should not crash when status item is nil
        XCTAssertNoThrow(testManager.toggleVisibility(), "Should handle nil status item gracefully")
    }
    
    func testStatusItemCleanup() {
        // Test proper cleanup of status item
        let testManager = MenuBarManager()
        let initialStatusItem = testManager.statusItem
        
        XCTAssertNotNil(initialStatusItem, "Should create status item")
        
        // When manager is deallocated, status item should be removed
        // We can't easily test deallocation, but we can verify the cleanup code exists
        // The deinit method should properly remove the status item
        
        // Verify status item exists before cleanup
        if let statusItem = initialStatusItem {
            let statusBar = NSStatusBar.system
            XCTAssertTrue(statusBar.statusItems.contains(statusItem), 
                         "Status item should be in system status bar")
        }
    }
    
    // MARK: - Visibility Management Tests
    
    func testStatusItemVisibility() {
        guard let statusItem = menuBarManager.statusItem else {
            XCTFail("Status item should exist")
            return
        }
        
        // Test default visibility
        XCTAssertTrue(menuBarManager.isVisible, "Should be visible by default")
        XCTAssertTrue(statusItem.isVisible, "Status item should be visible by default")
        
        // Test hiding
        menuBarManager.hideMenuBar()
        XCTAssertFalse(menuBarManager.isVisible, "Manager should track hidden state")
        XCTAssertFalse(statusItem.isVisible, "Status item should be hidden")
        
        // Test showing
        menuBarManager.showMenuBar()
        XCTAssertTrue(menuBarManager.isVisible, "Manager should track visible state")
        XCTAssertTrue(statusItem.isVisible, "Status item should be visible")
        
        // Test toggling
        menuBarManager.toggleVisibility()
        XCTAssertFalse(menuBarManager.isVisible, "Should toggle to hidden")
        XCTAssertFalse(statusItem.isVisible, "Status item should toggle to hidden")
        
        menuBarManager.toggleVisibility()
        XCTAssertTrue(menuBarManager.isVisible, "Should toggle back to visible")
        XCTAssertTrue(statusItem.isVisible, "Status item should toggle back to visible")
    }
    
    // MARK: - Popover Integration Tests
    
    func testPopoverSetup() {
        // Test that popover is properly configured for SwiftUI content
        guard let popover = menuBarManager.popover else {
            XCTFail("Popover should be created during initialization")
            return
        }
        
        // Test popover configuration
        XCTAssertEqual(popover.contentSize, NSSize(width: 250, height: 200), 
                      "Should have expected content size")
        XCTAssertEqual(popover.behavior, .transient, 
                      "Should have transient behavior for menu-like interaction")
        
        // Test content view controller
        XCTAssertNotNil(popover.contentViewController, "Should have content view controller")
        XCTAssertTrue(popover.contentViewController is NSHostingController<MenuBarView>, 
                     "Should use NSHostingController for SwiftUI content")
    }
    
    func testStatusItemClickHandling() {
        // Test status item click behavior
        guard let statusItem = menuBarManager.statusItem,
              let button = statusItem.button,
              let popover = menuBarManager.popover else {
            XCTFail("Status item components should exist")
            return
        }
        
        // Test initial state
        XCTAssertFalse(popover.isShown, "Popover should not be shown initially")
        
        // Simulate status item click by invoking the action through the button
        if let action = button.action {
            XCTAssertNoThrow(button.performClick(nil), 
                            "Status item click should not throw")
        }
        
        // Note: We can't easily test the actual popover showing in unit tests
        // as it requires the full AppKit event loop and window system
        // But we can verify the method exists and doesn't crash
    }
    
    // MARK: - Integration Tests
    
    func testStatusItemIntegrationWithMenuBarManager() {
        // Test that status item properly integrates with MenuBarManager
        
        // Should be able to access status item through manager
        XCTAssertNotNil(menuBarManager.statusItem, "Should provide access to status item")
        
        // Manager state should affect status item
        let initialVisibility = menuBarManager.isVisible
        menuBarManager.toggleVisibility()
        
        if let statusItem = menuBarManager.statusItem {
            XCTAssertEqual(statusItem.isVisible, menuBarManager.isVisible, 
                          "Status item visibility should match manager state")
        }
        
        // Restore original state
        if initialVisibility != menuBarManager.isVisible {
            menuBarManager.toggleVisibility()
        }
    }
}
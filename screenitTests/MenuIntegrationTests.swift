import XCTest
import SwiftUI
import AppKit
@testable import screenit

@MainActor
final class MenuIntegrationTests: XCTestCase {
    var menuBarManager: MenuBarManager!
    
    @MainActor override func setUp() {
        super.setUp()
        menuBarManager = MenuBarManager()
    }
    
    @MainActor override func tearDown() {
        menuBarManager?.cleanup()
        menuBarManager = nil
        super.tearDown()
    }
    
    // MARK: - Popover Integration Tests
    
    func testPopoverCreation() {
        // Given - MenuBarManager is initialized
        
        // Then - Popover should be created and configured
        XCTAssertNotNil(menuBarManager.popover, "Popover should be created during initialization")
        
        if let popover = menuBarManager.popover {
            XCTAssertEqual(popover.contentSize.width, 250, "Popover width should be 250")
            XCTAssertEqual(popover.contentSize.height, 200, "Popover height should be 200")
            XCTAssertEqual(popover.behavior, .transient, "Popover should have transient behavior")
            XCTAssertTrue(popover.animates, "Popover should animate")
            XCTAssertNotNil(popover.contentViewController, "Popover should have content view controller")
        }
    }
    
    func testPopoverContentViewController() {
        // Given - MenuBarManager is initialized
        guard let popover = menuBarManager.popover else {
            XCTFail("Popover should exist")
            return
        }
        
        // Then - Content view controller should be NSHostingController with MenuBarView
        XCTAssertTrue(popover.contentViewController is NSHostingController<MenuBarView>,
                     "Content view controller should be NSHostingController with MenuBarView")
    }
    
    func testMenuPresentation() {
        // Given - MenuBarManager with status item and popover
        guard let statusItem = menuBarManager.statusItem,
              let button = statusItem.button,
              let popover = menuBarManager.popover else {
            XCTFail("Status item, button, and popover should exist")
            return
        }
        
        // When - Status item is clicked (menu should show)
        let initiallyShown = popover.isShown
        menuBarManager.statusItemClicked()
        
        // Then - Popover should be shown (or hidden if it was already shown)
        XCTAssertNotEqual(popover.isShown, initiallyShown, "Popover visibility should toggle")
    }
    
    func testMenuDismissal() {
        // Given - MenuBarManager with popover
        guard let popover = menuBarManager.popover else {
            XCTFail("Popover should exist")
            return
        }
        
        // Ensure popover is shown first
        if !popover.isShown {
            menuBarManager.statusItemClicked()
        }
        
        // When - Status item is clicked again (menu should hide)
        if popover.isShown {
            menuBarManager.statusItemClicked()
            
            // Then - Popover should be hidden
            XCTAssertFalse(popover.isShown, "Popover should be hidden after second click")
        }
    }
    
    // MARK: - Menu State Management Tests
    
    func testMenuToggleBehavior() {
        // Given - MenuBarManager with popover
        guard let popover = menuBarManager.popover else {
            XCTFail("Popover should exist")
            return
        }
        
        let initialState = popover.isShown
        
        // When - Status item is clicked multiple times
        menuBarManager.statusItemClicked()
        let afterFirstClick = popover.isShown
        
        menuBarManager.statusItemClicked()
        let afterSecondClick = popover.isShown
        
        // Then - Popover should toggle state with each click
        XCTAssertNotEqual(afterFirstClick, initialState, "First click should toggle state")
        XCTAssertEqual(afterSecondClick, initialState, "Second click should return to initial state")
    }
    
    func testPopoverBehaviorConfiguration() {
        // Given - Popover is created
        guard let popover = menuBarManager.popover else {
            XCTFail("Popover should exist")
            return
        }
        
        // Then - Popover should have proper transient behavior
        XCTAssertEqual(popover.behavior, .transient, 
                      "Popover should have transient behavior for proper menu-like dismissal")
    }
    
    // MARK: - Error Handling Tests
    
    func testMenuPresentationWithoutStatusItem() {
        // Given - MenuBarManager without status item
        menuBarManager.cleanup() // Remove status item
        
        // When - Attempting to show menu
        // Should not crash when status item is nil
        menuBarManager.statusItemClicked()
        
        // Then - Should handle gracefully (no crash)
        XCTAssertTrue(true, "Should handle missing status item gracefully")
    }
    
    func testMenuPresentationWithoutPopover() {
        // Given - MenuBarManager with status item but no popover
        menuBarManager.popover = nil
        
        // When - Attempting to show menu
        // Should not crash when popover is nil
        menuBarManager.statusItemClicked()
        
        // Then - Should handle gracefully (no crash)
        XCTAssertTrue(true, "Should handle missing popover gracefully")
    }
    
    // MARK: - Integration with MenuBarView Tests
    
    func testMenuBarViewEnvironmentObject() {
        // Given - MenuBarManager with popover
        guard let popover = menuBarManager.popover,
              let hostingController = popover.contentViewController as? NSHostingController<MenuBarView> else {
            XCTFail("Popover should have NSHostingController with MenuBarView")
            return
        }
        
        // When - Accessing the root view
        let rootView = hostingController.rootView
        
        // Then - MenuBarView should be properly configured
        XCTAssertNotNil(rootView, "Root view should exist")
        // Note: Environment object testing requires more complex setup with SwiftUI testing
    }
    
    // MARK: - Accessibility Tests
    
    func testStatusItemAccessibility() {
        // Given - MenuBarManager with status item
        guard let statusItem = menuBarManager.statusItem,
              let button = statusItem.button,
              let cell = button.cell else {
            XCTFail("Status item, button, and cell should exist")
            return
        }
        
        // Then - Accessibility should be properly configured
        XCTAssertNotNil(cell.accessibilityTitle(), "Status item should have accessibility title")
    }
}

// MARK: - Helper Extensions

private extension MenuBarManager {
    /// Expose statusItemClicked for testing
    func statusItemClicked() {
        // Call the private @objc method via selector
        perform(#selector(MenuBarManager.statusItemClicked))
    }
}
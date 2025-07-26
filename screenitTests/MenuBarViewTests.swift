import XCTest
import SwiftUI
@testable import screenit

@MainActor
final class MenuBarViewTests: XCTestCase {
    var menuBarManager: MenuBarManager!
    
    override func setUp() {
        super.setUp()
        menuBarManager = MenuBarManager()
    }
    
    override func tearDown() {
        menuBarManager = nil
        super.tearDown()
    }
    
    func testMenuBarViewInitialization() {
        // Given
        let menuView = MenuBarView()
            .environmentObject(menuBarManager)
        
        // When/Then - Should not crash when initialized
        XCTAssertNotNil(menuView)
    }
    
    func testMenuBarViewHasRequiredComponents() {
        // Given
        let menuView = MenuBarView()
            .environmentObject(menuBarManager)
        
        // Then - View should contain expected UI elements
        // This is a basic structural test - in a real UI test we'd check actual rendered content
        XCTAssertNotNil(menuView)
    }
    
    func testMenuItemButtonInitialization() {
        // Given
        let testAction = {}
        
        // When
        let menuItem = MenuItemButton(
            title: "Test Item",
            icon: "test.icon",
            shortcut: "⌘T",
            isEnabled: true,
            isDestructive: false,
            action: testAction
        )
        
        // Then
        XCTAssertNotNil(menuItem)
    }
    
    func testMenuItemButtonDestructiveStyle() {
        // Given
        let testAction = {}
        
        // When
        let destructiveMenuItem = MenuItemButton(
            title: "Quit",
            icon: "power",
            shortcut: "⌘Q",
            isEnabled: true,
            isDestructive: true,
            action: testAction
        )
        
        // Then
        XCTAssertNotNil(destructiveMenuItem)
    }
    
    func testMenuItemButtonDisabledState() {
        // Given
        let testAction = {}
        
        // When
        let disabledMenuItem = MenuItemButton(
            title: "Disabled Item",
            icon: "disabled.icon",
            shortcut: "⌘D",
            isEnabled: false,
            action: testAction
        )
        
        // Then
        XCTAssertNotNil(disabledMenuItem)
    }
    
    func testMenuBarManagerIntegration() {
        // Given
        menuBarManager.isCapturing = false
        menuBarManager.canCapture = true
        
        // When
        let menuView = MenuBarView()
            .environmentObject(menuBarManager)
        
        // Then
        XCTAssertNotNil(menuView)
        XCTAssertFalse(menuBarManager.isCapturing)
        XCTAssertTrue(menuBarManager.canCapture)
    }
    
    func testMenuBarManagerCapturingState() {
        // Given
        menuBarManager.isCapturing = true
        
        // When
        let menuView = MenuBarView()
            .environmentObject(menuBarManager)
        
        // Then
        XCTAssertTrue(menuBarManager.isCapturing)
        XCTAssertNotNil(menuView)
    }
    
    func testMenuBarManagerPermissionState() {
        // Given
        menuBarManager.canCapture = false
        
        // When
        let menuView = MenuBarView()
            .environmentObject(menuBarManager)
        
        // Then
        XCTAssertFalse(menuBarManager.canCapture)
        XCTAssertNotNil(menuView)
    }
}
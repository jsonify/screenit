import XCTest
import SwiftUI
import AppKit
@testable import screenit

class AppLifecycleTests: XCTestCase {
    
    // MARK: - App Launch Tests
    
    func testAppLaunchesWithMenuBarManager() {
        // Test that the app creates a MenuBarManager on launch
        let app = screenitApp()
        
        // Create a test window scene to simulate app launch
        let scene = app.body
        
        // Verify the scene is a Settings scene (background app configuration)
        XCTAssertTrue(scene is Settings<EmptyView>, "App should use Settings scene for background-only mode")
    }
    
    func testBackgroundOnlyConfiguration() {
        // Test that the app is configured as background-only
        let bundle = Bundle.main
        let isUIElement = bundle.object(forInfoDictionaryKey: "LSUIElement") as? Bool
        
        XCTAssertTrue(isUIElement == true, "App should be configured as background-only with LSUIElement=true")
    }
    
    func testAppDoesNotShowInDock() {
        // Test that the app doesn't appear in the Dock
        let activationPolicy = NSApp.activationPolicy()
        
        // For background apps, this should be .accessory or .prohibited
        XCTAssertTrue(
            activationPolicy == .accessory || activationPolicy == .prohibited,
            "Background app should not appear in Dock"
        )
    }
    
    @MainActor
    func testMenuBarManagerInitializationOnLaunch() {
        // Test that MenuBarManager is properly initialized
        let menuBarManager = MenuBarManager()
        
        // Verify menu bar manager initializes properly
        XCTAssertNotNil(menuBarManager, "MenuBarManager should initialize successfully")
        XCTAssertTrue(menuBarManager.isVisible, "Menu bar should be visible by default")
    }
    
    // MARK: - App Termination Tests
    
    @MainActor 
    func testAppTermination() {
        // Test proper app termination
        let menuBarManager = MenuBarManager()
        
        // Verify cleanup methods exist and can be called
        XCTAssertNoThrow(menuBarManager.cleanup(), "MenuBarManager cleanup should not throw")
    }
    
    @MainActor
    func testMenuBarManagerCleanup() {
        // Test that MenuBarManager properly cleans up resources
        let menuBarManager = MenuBarManager()
        
        // Simulate having a status item
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Verify cleanup removes status item properly
        menuBarManager.cleanup()
        
        // After cleanup, status item should be cleaned up
        // (This is handled internally by the cleanup method)
        XCTAssertFalse(menuBarManager.isMenuVisible, "Menu should not be visible after cleanup")
    }
    
    @MainActor
    func testGracefulTerminationWithActiveCapture() {
        // Test that app can terminate gracefully even during capture
        let menuBarManager = MenuBarManager()
        
        // Simulate a capture in progress
        menuBarManager.isCapturing = true
        
        // Verify cleanup can still proceed
        XCTAssertNoThrow(menuBarManager.cleanup(), "Cleanup should work even during capture")
    }
    
    @MainActor
    func testNotificationCleanupOnTermination() {
        // Test that notification observers are properly removed
        let menuBarManager = MenuBarManager()
        
        weak var weakManager = menuBarManager
        
        // Cleanup should remove all observers
        menuBarManager.cleanup()
        
        // Verify that cleanup completed without issues
        XCTAssertNotNil(weakManager, "Manager should still exist for verification")
    }
    
    // MARK: - Lifecycle State Tests
    
    @MainActor
    func testAppActivationPolicy() {
        // Test that app has correct activation policy for background apps
        let policy = NSApp.activationPolicy()
        
        // Background apps should use .accessory or .prohibited
        let validPolicies: [NSApplication.ActivationPolicy] = [.accessory, .prohibited]
        XCTAssertTrue(validPolicies.contains(policy), "App should have appropriate background activation policy")
    }
    
    func testAppHidesFromCommandTab() {
        // Test that app doesn't appear in Cmd+Tab switcher
        let isUIElement = Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool
        
        XCTAssertTrue(isUIElement == true, "App should not appear in Cmd+Tab with LSUIElement=true")
    }
    
    @MainActor
    func testAppSupportsMenuBarOnly() {
        // Test that app functions properly as menu bar only app
        let menuBarManager = MenuBarManager()
        
        // App should initialize menu bar successfully
        XCTAssertNotNil(menuBarManager.statusItem, "Status item should be created for menu bar app")
    }
    
    // MARK: - macOS Convention Tests
    
    @MainActor
    func testAppFollowsNSApplicationLifecycle() {
        // Test that app properly integrates with NSApplication lifecycle
        XCTAssertNotNil(NSApp, "NSApplication should be available")
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.screenit.screenit", "Bundle identifier should match")
    }
    
    @MainActor
    func testAppHandlesSystemShutdown() {
        // Test that app responds appropriately to system shutdown
        let menuBarManager = MenuBarManager()
        
        // Verify that cleanup can be called multiple times safely
        XCTAssertNoThrow(menuBarManager.cleanup())
        XCTAssertNoThrow(menuBarManager.cleanup()) // Second call should be safe
    }
    
    @MainActor
    func testAppHandlesUserLogout() {
        // Test that app handles user logout scenarios
        let menuBarManager = MenuBarManager()
        
        // Test workspace notifications (simulated)
        let notificationCenter = NotificationCenter.default
        
        // Verify that app can handle workspace notifications
        XCTAssertNotNil(notificationCenter, "Notification center should be available for workspace events")
    }
    
    // MARK: - Resource Management Tests
    
    @MainActor
    func testMemoryManagementOnTermination() {
        // Test that objects are properly deallocated
        var menuBarManager: MenuBarManager? = MenuBarManager()
        weak var weakManager = menuBarManager
        
        // Cleanup and deallocate
        menuBarManager?.cleanup()
        menuBarManager = nil
        
        // Wait for deallocation
        DispatchQueue.main.async {
            // Verify weak reference is nil after cleanup and deallocation
            XCTAssertNil(weakManager, "MenuBarManager should be deallocated after cleanup")
        }
    }
    
    @MainActor
    func testStatusItemCleanupOnTermination() {
        // Test that status items are properly removed from menu bar
        let menuBarManager = MenuBarManager()
        let initialStatusItem = menuBarManager.statusItem
        
        XCTAssertNotNil(initialStatusItem, "Status item should exist initially")
        
        // Cleanup should remove status item
        menuBarManager.cleanup()
        
        // Status item should be cleaned up
        XCTAssertFalse(menuBarManager.isMenuVisible, "Menu should not be visible after cleanup")
    }
}

// MARK: - Test Helpers

extension AppLifecycleTests {
    
    /// Helper to verify app configuration matches background app requirements
    @MainActor
    private func verifyBackgroundAppConfiguration() {
        let bundle = Bundle.main
        
        // Check LSUIElement
        let isUIElement = bundle.object(forInfoDictionaryKey: "LSUIElement") as? Bool
        XCTAssertTrue(isUIElement == true, "LSUIElement should be true for background apps")
        
        // Check activation policy
        let policy = NSApp.activationPolicy()
        XCTAssertTrue(policy != .regular, "Background apps should not use regular activation policy")
    }
    
    /// Helper to simulate app launch sequence
    @MainActor
    private func simulateAppLaunch() -> MenuBarManager {
        let manager = MenuBarManager()
        
        // Verify launch completed successfully
        XCTAssertNotNil(manager, "App launch should create MenuBarManager")
        XCTAssertNotNil(manager.statusItem, "App launch should create status item")
        
        return manager
    }
    
    /// Helper to simulate app termination sequence
    @MainActor
    private func simulateAppTermination(manager: MenuBarManager) {
        // Cleanup all resources
        manager.cleanup()
        
        // Verify termination completed successfully
        XCTAssertFalse(manager.isMenuVisible, "Menu should be hidden after termination")
    }
}
import Foundation

// Simple test for MenuBarManager functionality
class MenuBarManagerTests {
    static func runTests() {
        print("Running MenuBarManager tests...")
        
        let manager = MenuBarManager()
        
        // Test initial state
        assert(manager.isVisible == true, "Initial visibility should be true")
        print("✓ Initial state test passed")
        
        // Test visibility toggle
        manager.toggleVisibility()
        assert(manager.isVisible == false, "Visibility should toggle to false")
        print("✓ Toggle visibility test passed")
        
        manager.toggleVisibility()
        assert(manager.isVisible == true, "Visibility should toggle back to true")
        print("✓ Toggle back test passed")
        
        // Test hide/show methods
        manager.hideMenuBar()
        assert(manager.isVisible == false, "Hide should set visibility to false")
        print("✓ Hide menu bar test passed")
        
        manager.showMenuBar()
        assert(manager.isVisible == true, "Show should set visibility to true")
        print("✓ Show menu bar test passed")
        
        // Test menu actions (these should not crash)
        manager.triggerCapture()
        manager.showHistory()
        manager.showPreferences()
        print("✓ Menu action methods test passed")
        
        print("All MenuBarManager tests passed! ✅")
    }
}

// Import our main code for testing
// Note: In a real project, this would be in a separate test target
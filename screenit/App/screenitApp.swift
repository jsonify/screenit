import SwiftUI
import AppKit

@main
struct screenitApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    
    init() {
        // Configure app as background-only (LSUIElement=true in Info.plist)
        // This ensures the app doesn't appear in the Dock or Cmd+Tab switcher
        // Note: Defer heavy initialization to prevent circular dependencies
    }
    
    var body: some Scene {
        // Use Settings scene for hidden background app
        // MenuBarManager handles the actual menu bar integration via NSStatusItem
        Settings {
            EmptyView()
                .onAppear {
                    // Initialize background app configuration after SwiftUI is ready
                    setupBackgroundAppConfiguration()
                }
        }
        .commands {
            // Remove default menu bar commands since this is a menu bar only app
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) { }
            CommandGroup(replacing: .importExport) { }
            CommandGroup(replacing: .toolbar) { }
            CommandGroup(replacing: .sidebar) { }
        }
    }
    
    // MARK: - Background App Configuration
    
    private func setupBackgroundAppConfiguration() {
        // Set activation policy to accessory (background app that can be activated)
        // This is automatically handled by LSUIElement=true in Info.plist
        // but we can verify and adjust if needed
        
        // Add safety delay to ensure NSApp is fully ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard NSApp.activationPolicy() != .prohibited else {
                print("⚠️ NSApp not ready yet, skipping background configuration")
                return
            }
            
            let currentPolicy = NSApp.activationPolicy()
            
            // For menu bar apps, .accessory is ideal (can show UI but doesn't appear in Dock)
            if currentPolicy == .regular {
                NSApp.setActivationPolicy(.accessory)
                print("Set app activation policy to accessory for background operation")
            }
            
            // Ensure app doesn't activate on launch
            NSApp.deactivate()
            
            // Enable automatic termination support (matching Info.plist settings)
            // These are configured in Info.plist with NSSupportsAutomaticTermination and NSSupportsSuddenTermination
            print("Automatic and sudden termination configured via Info.plist")
            
            // Set up proper application delegate behaviors for menu bar apps
            NSApp.servicesProvider = nil // Disable services menu for background apps
            
            print("Background app configuration complete - policy: \(NSApp.activationPolicy())")
        }
    }
}
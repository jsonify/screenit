import SwiftUI
import Combine

class MenuBarManager: ObservableObject {
    @Published var isVisible: Bool = true
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Future: Set up global hotkey monitoring
        // For now, keyboard shortcuts are handled by MenuBarExtra
    }
    
    // MARK: - Menu Actions
    
    func triggerCapture() {
        print("Capture Area triggered")
        // TODO: Implement capture functionality in Phase 1
    }
    
    func showHistory() {
        print("Show History triggered")
        // TODO: Implement history view in Phase 4
    }
    
    func showPreferences() {
        print("Preferences triggered")
        // TODO: Implement preferences window in Phase 5
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Menu Bar Visibility
    
    func toggleVisibility() {
        isVisible.toggle()
    }
    
    func hideMenuBar() {
        isVisible = false
    }
    
    func showMenuBar() {
        isVisible = true
    }
}
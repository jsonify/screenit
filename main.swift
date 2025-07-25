import SwiftUI

@main
struct ScreenitApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    
    var body: some Scene {
        MenuBarExtra("screenit", systemImage: "camera.viewfinder") {
            MenuBarView()
                .environmentObject(menuBarManager)
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuBarView: View {
    @EnvironmentObject var menuBarManager: MenuBarManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button("Capture Area") {
                menuBarManager.triggerCapture()
            }
            .keyboardShortcut("4", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Show History") {
                menuBarManager.showHistory()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Preferences...") {
                menuBarManager.showPreferences()
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            Button("Quit screenit") {
                menuBarManager.quitApp()
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.vertical, 4)
    }
}

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
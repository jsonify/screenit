import SwiftUI

@main
struct screenitApp: App {
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
            Button(action: {
                menuBarManager.triggerCapture()
            }) {
                HStack {
                    Text("Capture Area")
                    Spacer()
                    if !menuBarManager.canCapture {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
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
        .alert("Screen Recording Permission Required", isPresented: $menuBarManager.showingPermissionAlert) {
            Button("Open System Preferences") {
                menuBarManager.openSystemPreferences()
            }
            Button("Cancel") {
                menuBarManager.dismissPermissionAlert()
            }
        } message: {
            Text(menuBarManager.permissionStatusMessage)
        }
    }
}
import SwiftUI
import UniformTypeIdentifiers

@main
struct ScreenitApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var captureEngine = CaptureEngine.shared
    
    var body: some Scene {
        MenuBarExtra("screenit", systemImage: "camera.viewfinder") {
            MenuBarView()
                .environmentObject(menuBarManager)
                .environmentObject(captureEngine)
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuBarView: View {
    @EnvironmentObject var menuBarManager: MenuBarManager
    @EnvironmentObject var captureEngine: CaptureEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button("Capture Area") {
                menuBarManager.triggerCapture()
            }
            .keyboardShortcut("4", modifiers: [.command, .shift])
            .disabled(captureEngine.isCapturing || captureEngine.authorizationStatus != "authorized")
            
            Divider()
            
            Button("Show History") {
                menuBarManager.showHistory()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            
            Divider()
            
            if captureEngine.authorizationStatus != "authorized" {
                Button("Grant Permissions...") {
                    Task {
                        await menuBarManager.requestCapturePermissions()
                    }
                }
                
                Divider()
            }
            
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
    private let captureEngine = CaptureEngine.shared
    
    init() {
        setupNotifications()
        
        // Initialize capture engine and check permissions
        Task {
            await captureEngine.refreshAvailableContent()
        }
    }
    
    private func setupNotifications() {
        // Future: Set up global hotkey monitoring
        // For now, keyboard shortcuts are handled by MenuBarExtra
    }
    
    // MARK: - Menu Actions
    
    func triggerCapture() {
        print("Capture Area triggered")
        
        Task {
            // Check authorization first
            guard captureEngine.authorizationStatus == "authorized" else {
                print("Screen capture not authorized")
                await requestCapturePermissions()
                return
            }
            
            // Capture full screen for now (area selection comes in next phase)
            if let image = await captureEngine.captureFullScreen() {
                print("Screen captured successfully: \(image.width)x\(image.height)")
                await saveImageToDesktop(image)
            } else {
                print("Screen capture failed")
                if let error = captureEngine.lastError {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func requestCapturePermissions() async {
        print("Requesting capture permissions")
        let granted = await captureEngine.requestAuthorization()
        if granted {
            print("Permissions granted")
            await captureEngine.refreshAvailableContent()
        } else {
            print("Permissions denied")
        }
    }
    
    private func saveImageToDesktop(_ image: CGImage) async {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let timestamp = DateFormatter().apply {
            $0.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        }.string(from: Date())
        let fileURL = desktopURL.appendingPathComponent("screenit-\(timestamp).png")
        
        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            print("Failed to create image destination")
            return
        }
        
        CGImageDestinationAddImage(destination, image, nil)
        
        if CGImageDestinationFinalize(destination) {
            print("Image saved to: \(fileURL.path)")
        } else {
            print("Failed to save image")
        }
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

// MARK: - Extensions

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}
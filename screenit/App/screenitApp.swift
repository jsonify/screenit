//
//  screenitApp.swift
//  screenit
//
//  Created by Jason Rueckert on 7/14/25.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct screenitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var captureEngine = CaptureEngine()
    @StateObject private var annotationEngine = AnnotationEngine()
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var globalHotkeyManager = GlobalHotkeyManager()
    
    @State private var showingCaptureOverlay = false
    @State private var showingHistory = false
    @State private var showingPermissionRequest = false
    @State private var hasInitialized = false
    @State private var showingCaptureWindow = false
    
    var body: some Scene {
        Settings {
            PreferencesView(captureEngine: captureEngine, globalHotkeyManager: globalHotkeyManager)
                .onAppear {
                    if !hasInitialized {
                        setupManagerRelationships()
                        setupNotifications()
                        hasInitialized = true
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        Window("Capture History", id: "history") {
            HistoryView(dataManager: dataManager)
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .keyboardShortcut("h", modifiers: [.command, .shift])
        
        Window("Capture Overlay", id: "capture-overlay") {
            Group {
                if captureEngine.needsPermissionSetup {
                    PermissionRequestView(
                        permissionError: captureEngine.permissionError,
                        onRetry: {
                            await captureEngine.retryPermissionCheck()
                        },
                        onOpenSystemSettings: {
                            openSystemSettings()
                        }
                    )
                    .background(Color.black.opacity(0.3))
                } else {
                    CaptureOverlayView(
                        captureEngine: captureEngine,
                        annotationEngine: annotationEngine,
                        onCaptureComplete: { image in
                            if let image = image {
                                dataManager.addCaptureItem(image: image, annotations: annotationEngine.annotations)
                                annotationEngine.clearAnnotations()
                            }
                            showingCaptureWindow = false
                        },
                        onCancel: {
                            showingCaptureWindow = false
                            annotationEngine.clearAnnotations()
                        }
                    )
                }
            }
            .ignoresSafeArea()
        }
        .windowStyle(.plain)
        .windowLevel(.floating)
        .windowResizability(.contentSize)
        
        Window("Permission Request", id: "permission-request") {
            PermissionRequestView(
                permissionError: captureEngine.permissionError,
                onRetry: {
                    await captureEngine.retryPermissionCheck()
                    if captureEngine.capturePermissionGranted {
                        showingPermissionRequest = false
                    }
                },
                onOpenSystemSettings: {
                    openSystemSettings()
                }
            )
            .frame(width: 500, height: 600)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
    
    private func setupManagerRelationships() {
        menuBarManager.captureEngine = captureEngine
        menuBarManager.dataManager = dataManager
        globalHotkeyManager.captureEngine = captureEngine
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .openHistoryWindow,
            object: nil,
            queue: .main
        ) { _ in
            self.openHistoryWindow()
        }
        
        NotificationCenter.default.addObserver(
            forName: .openPreferencesWindow,
            object: nil,
            queue: .main
        ) { _ in
            self.openPreferencesWindow()
        }
        
        NotificationCenter.default.addObserver(
            forName: .openCaptureWindow,
            object: nil,
            queue: .main
        ) { _ in
            self.openCaptureWindow()
        }
    }
    
    private func openHistoryWindow() {
        // Try to find existing history window or open new one
        for window in NSApp.windows {
            if window.title == "Capture History" {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        // If not found, the window will be created by the SwiftUI framework
        // We can use keyboard shortcut to trigger it
        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint.zero,
            modifierFlags: [.command, .shift],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "h",
            charactersIgnoringModifiers: "h",
            isARepeat: false,
            keyCode: 4
        )
        if let event = event {
            NSApp.sendEvent(event)
        }
    }
    
    private func openPreferencesWindow() {
        // For SwiftUI Settings scenes, we need to use the environment approach
        // This will open the Settings window defined in the Scene
        if let settingsWindow = NSApp.windows.first(where: { $0.title == "screenit Settings" }) {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Fallback to keyboard shortcut approach
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }
    
    private func openCaptureWindow() {
        // Try to find and open the capture overlay window
        for window in NSApp.windows {
            if window.identifier?.rawValue == "capture-overlay" {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        // If no window found, create it by toggling showingCaptureWindow
        showingCaptureWindow = true
        
        // Then find it again and make it visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApp.windows {
                if window.identifier?.rawValue == "capture-overlay" {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    NSApp.activate(ignoringOtherApps: true)
                    break
                }
            }
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct PreferencesView: View {
    @ObservedObject var captureEngine: CaptureEngine
    @ObservedObject var globalHotkeyManager: GlobalHotkeyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.title2)
                .fontWeight(.semibold)
            
            GroupBox("Permissions") {
                VStack(alignment: .leading, spacing: 8) {
                    PermissionStatusIndicator(
                        isGranted: captureEngine.capturePermissionGranted,
                        error: captureEngine.permissionError
                    )
                    
                    if !captureEngine.capturePermissionGranted {
                        Button("Request Permission") {
                            Task {
                                await captureEngine.retryPermissionCheck()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(8)
            }
            
            GroupBox("Keyboard Shortcuts") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Global Hotkeys")
                                .fontWeight(.medium)
                            Text("Enable system-wide keyboard shortcuts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { globalHotkeyManager.isEnabled },
                            set: { enabled in
                                if enabled {
                                    globalHotkeyManager.enableGlobalHotkeys()
                                } else {
                                    globalHotkeyManager.disableGlobalHotkeys()
                                }
                            }
                        ))
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Capture Area:")
                        Spacer()
                        Text("⌘⇧4")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(globalHotkeyManager.isActuallyWorking ? .primary : .secondary)
                    }
                    
                    HStack {
                        Text("Show History:")
                        Spacer()
                        Text("⌘⇧H")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    if globalHotkeyManager.isEnabled && !globalHotkeyManager.isActuallyWorking {
                        Text("⚠️ Accessibility permission required for global hotkeys")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(8)
            }
            
            GroupBox("Storage") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("History Limit:")
                        Spacer()
                        Text("10 captures")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Older captures are automatically deleted when the limit is reached.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 450, height: 380)
    }
}

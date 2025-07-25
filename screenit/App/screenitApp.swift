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
    @State private var showingPreferences = false
    @State private var hasInitialized = false
    @State private var showingCaptureWindow = false
    
    var body: some Scene {
        // Menu bar only app - no main window
        // Initialize managers when the app starts
        WindowGroup {
            EmptyView()
                .onAppear {
                    if !hasInitialized {
                        setupManagerRelationships()
                        setupNotifications()
                        hasInitialized = true
                    }
                }
                .frame(width: 0, height: 0)
                .hidden()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        Window("Preferences", id: "preferences") {
            PreferencesView(captureEngine: captureEngine, globalHotkeyManager: globalHotkeyManager)
                .onDisappear {
                    showingPreferences = false
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        
        Window("Capture History", id: "history") {
            HistoryView(dataManager: dataManager)
                .frame(minWidth: 600, minHeight: 400)
                .onDisappear {
                    showingHistory = false
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .keyboardShortcut("h", modifiers: [.command, .shift])
        
        Window("Capture Overlay", id: "capture-overlay") {
            if showingCaptureWindow {
                ZStack {
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
                .onAppear {
                    // Make sure window appears properly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        for window in NSApp.windows {
                            if window.identifier?.rawValue == "capture-overlay" {
                                window.makeKeyAndOrderFront(nil)
                                window.orderFrontRegardless()
                                window.level = .floating
                                NSApp.activate(ignoringOtherApps: true)
                                break
                            }
                        }
                    }
                }
            } else {
                EmptyView()
                    .frame(width: 0, height: 0)
                    .hidden()
            }
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
            print("App: Received openCaptureWindow notification")
            self.openCaptureWindow()
        }
    }
    
    private func openHistoryWindow() {
        // First try to find and activate existing window
        for window in NSApp.windows {
            if window.title == "Capture History" || window.identifier?.rawValue == "history" {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        // Create new history window by setting state
        showingHistory = true
        
        // Give SwiftUI time to create the window, then activate it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            for window in NSApp.windows {
                if window.title == "Capture History" || window.identifier?.rawValue == "history" {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                    return
                }
            }
        }
    }
    
    private func openPreferencesWindow() {
        // First try to find and activate existing window
        for window in NSApp.windows {
            if window.title == "Preferences" || window.identifier?.rawValue == "preferences" {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        // Create new preferences window by setting state
        showingPreferences = true
        
        // Give SwiftUI time to create the window, then activate it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            for window in NSApp.windows {
                if window.title == "Preferences" || window.identifier?.rawValue == "preferences" {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                    return
                }
            }
        }
    }
    
    private func openCaptureWindow() {
        // Simply set the state - SwiftUI will handle window creation
        showingCaptureWindow = true
        print("Opening capture window - showingCaptureWindow set to true")
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

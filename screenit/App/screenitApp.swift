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
    
    @State private var showingCaptureOverlay = false
    @State private var showingHistory = false
    @State private var showingPermissionRequest = false
    
    var body: some Scene {
        Settings {
            PreferencesView(captureEngine: captureEngine)
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
                            showingCaptureOverlay = false
                        },
                        onCancel: {
                            showingCaptureOverlay = false
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
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct PreferencesView: View {
    @ObservedObject var captureEngine: CaptureEngine
    
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
                        Text("Capture Area:")
                        Spacer()
                        Text("⌘⇧4")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Show History:")
                        Spacer()
                        Text("⌘⇧H")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
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
                }
                .padding(8)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

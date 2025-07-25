//
//  MenuBarManager.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import Foundation
import SwiftUI
import AppKit

@MainActor
class MenuBarManager: ObservableObject {
    private var statusBarItem: NSStatusItem?
    @Published var isVisible = true
    
    weak var captureEngine: CaptureEngine?
    weak var dataManager: DataManager?
    
    init() {
        print("MenuBarManager: Initializing...")
        setupMenuBar()
        print("MenuBarManager: Initialization complete")
    }
    
    func setupMenuBar() {
        print("MenuBarManager: Setting up menu bar...")
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            print("MenuBarManager: Setting up button...")
            // Try to use app icon first, fallback to system symbol
            if let appIcon = NSImage(named: "AppIcon") {
                button.image = appIcon
                button.image?.size = NSSize(width: 16, height: 16)
                print("MenuBarManager: Using app icon")
            } else {
                button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "screenit")
                print("MenuBarManager: Using system symbol")
            }
            
            button.target = self
            button.action = #selector(menuBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            // Also handle left mouse down for immediate response
            button.setButtonType(.momentaryChange)
            
            // Improve button appearance
            button.appearsDisabled = false
            button.toolTip = "screenit - Screen Capture Tool"
            print("MenuBarManager: Button setup complete")
        } else {
            print("MenuBarManager: ERROR - Could not get status bar button")
        }
        
        updateMenu()
        print("MenuBarManager: Menu bar setup complete")
    }
    
    @objc private func menuBarButtonClicked() {
        guard let event = NSApp.currentEvent else {
            // If no event, default to capture (left click)
            triggerCapture()
            return
        }
        
        // Check for right click or control+click
        if event.type == .rightMouseUp || 
           event.type == .rightMouseDown ||
           (event.type == .leftMouseUp && event.modifierFlags.contains(.control)) {
            showContextMenu()
        } else {
            // Default behavior is capture
            triggerCapture()
        }
    }
    
    private func showContextMenu() {
        print("MenuBarManager: showContextMenu() called")
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        // Primary action - Capture Area
        let captureItem = NSMenuItem(title: "Capture Area", action: #selector(captureArea), keyEquivalent: "")
        captureItem.target = self
        captureItem.isEnabled = true
        captureItem.keyEquivalentModifierMask = [.command, .shift]
        captureItem.keyEquivalent = "4"
        menu.addItem(captureItem)
        print("MenuBarManager: Added capture item with target: \(String(describing: captureItem.target))")
        
        menu.addItem(NSMenuItem.separator())
        
        // History and Preferences
        let historyItem = NSMenuItem(title: "Show History", action: #selector(showHistory), keyEquivalent: "h")
        historyItem.target = self
        historyItem.isEnabled = true
        historyItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(historyItem)
        print("MenuBarManager: Added history item with target: \(String(describing: historyItem.target))")
        
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        preferencesItem.isEnabled = true
        preferencesItem.keyEquivalentModifierMask = [.command]
        menu.addItem(preferencesItem)
        print("MenuBarManager: Added preferences item with target: \(String(describing: preferencesItem.target))")
        
        menu.addItem(NSMenuItem.separator())
        
        // App info and quit
        let aboutItem = NSMenuItem(title: "About screenit", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        aboutItem.isEnabled = true
        menu.addItem(aboutItem)
        print("MenuBarManager: Added about item with target: \(String(describing: aboutItem.target))")
        
        let quitItem = NSMenuItem(title: "Quit screenit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        quitItem.isEnabled = true
        quitItem.keyEquivalentModifierMask = [.command]
        menu.addItem(quitItem)
        print("MenuBarManager: Added quit item with target: \(String(describing: quitItem.target))")
        
        // Show the menu using the proper NSMenu presentation method
        if let button = statusBarItem?.button {
            print("MenuBarManager: Showing menu with popUp()")
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.frame.height), in: button)
        } else {
            print("MenuBarManager: ERROR - No button found for menu presentation")
        }
    }
    
    private func updateMenu() {
        
    }
    
    @objc private func captureArea() {
        print("MenuBarManager: captureArea() called")
        triggerCapture()
    }
    
    @objc private func showHistory() {
        print("MenuBarManager: showHistory() called")
        // Post notification to open the history window
        NotificationCenter.default.post(name: .openHistoryWindow, object: nil)
    }
    
    @objc private func showPreferences() {
        print("MenuBarManager: showPreferences() called")
        // Post notification to open the preferences window
        NotificationCenter.default.post(name: .openPreferencesWindow, object: nil)
    }
    
    @objc private func showAbout() {
        print("MenuBarManager: showAbout() called")
        // Show standard macOS about panel
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func triggerCapture() {
        print("MenuBarManager: triggerCapture() called")
        Task {
            print("MenuBarManager: Checking permissions...")
            await captureEngine?.checkAndRequestPermission()
            // Post notification to open capture overlay window
            await MainActor.run {
                print("MenuBarManager: Posting openCaptureWindow notification")
                NotificationCenter.default.post(name: .openCaptureWindow, object: nil)
            }
        }
    }
    
    func hide() {
        statusBarItem = nil
        isVisible = false
    }
    
    func show() {
        if statusBarItem == nil {
            setupMenuBar()
        }
        isVisible = true
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let openHistoryWindow = Notification.Name("openHistoryWindow")
    static let openPreferencesWindow = Notification.Name("openPreferencesWindow")
    static let openCaptureWindow = Notification.Name("openCaptureWindow")
}
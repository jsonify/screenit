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
        setupMenuBar()
    }
    
    func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Screen Capture")
            button.target = self
            button.action = #selector(menuBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        updateMenu()
    }
    
    @objc private func menuBarButtonClicked() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            triggerCapture()
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        let captureItem = NSMenuItem(title: "Capture Area", action: #selector(captureArea), keyEquivalent: "")
        captureItem.target = self
        menu.addItem(captureItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let historyItem = NSMenuItem(title: "Show History", action: #selector(showHistory), keyEquivalent: "h")
        historyItem.target = self
        menu.addItem(historyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let preferencesItem = NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit screenit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusBarItem?.menu = menu
        statusBarItem?.button?.performClick(nil)
        statusBarItem?.menu = nil
    }
    
    private func updateMenu() {
        
    }
    
    @objc private func captureArea() {
        triggerCapture()
    }
    
    @objc private func showHistory() {
        // Post notification to open the history window
        NotificationCenter.default.post(name: .openHistoryWindow, object: nil)
    }
    
    @objc private func showPreferences() {
        // Post notification to open the preferences window
        NotificationCenter.default.post(name: .openPreferencesWindow, object: nil)
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func triggerCapture() {
        Task {
            await captureEngine?.checkAndRequestPermission()
            // Post notification to open capture overlay window
            await MainActor.run {
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
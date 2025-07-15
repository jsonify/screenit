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
        
        menu.addItem(NSMenuItem(title: "Capture Area", action: #selector(captureArea), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show History", action: #selector(showHistory), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit screenit", action: #selector(quit), keyEquivalent: "q"))
        
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
        
    }
    
    @objc private func showPreferences() {
        
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func triggerCapture() {
        Task {
            await captureEngine?.checkAndRequestPermission()
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
//
//  GlobalHotkeyManager.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import Foundation
import AppKit
import Carbon

class GlobalHotkeyManager: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let preferences = PreferencesManager.shared
    
    weak var captureEngine: CaptureEngine?
    
    init() {
        setupGlobalHotkeys()
        
        // Enable hotkeys if preference is set
        if preferences.globalHotkeysEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.enableGlobalHotkeys()
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func setupGlobalHotkeys() {
        // Request accessibility permission first
        guard checkAccessibilityPermission() else {
            print("Accessibility permission required for global hotkeys")
            requestAccessibilityPermission()
            return
        }
        
        startMonitoring()
    }
    
    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrustedWithOptions([
            kAXTrustedCheckOptionPrompt.takeRetainedValue(): false
        ] as CFDictionary)
    }
    
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        if !trusted {
            // The system dialog should have appeared, but let's also provide guidance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "To enable global hotkeys, please:\n\n1. Go to System Settings > Privacy & Security > Accessibility\n2. Click the '+' button to add screenit\n3. Enable the checkbox next to screenit"
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Cancel")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
    private func startMonitoring() {
        guard eventTap == nil else { return }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleGlobalKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
                self.runLoopSource = nil
            }
            
            self.eventTap = nil
        }
    }
    
    private func handleGlobalKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Check for Cmd+Shift+4 (keyCode 21 = '4')
        if keyCode == 21 && 
           flags.contains(.maskCommand) && 
           flags.contains(.maskShift) {
            
            // Trigger capture on main thread
            DispatchQueue.main.async {
                self.triggerCapture()
            }
            
            // Consume the event to prevent system screenshot
            return nil
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func triggerCapture() {
        Task {
            await captureEngine?.checkAndRequestPermission()
        }
    }
    
    func enableGlobalHotkeys() {
        preferences.globalHotkeysEnabled = true
        
        if !checkAccessibilityPermission() {
            requestAccessibilityPermission()
        } else if eventTap == nil {
            startMonitoring()
        }
    }
    
    func disableGlobalHotkeys() {
        stopMonitoring()
        preferences.globalHotkeysEnabled = false
    }
    
    var isEnabled: Bool {
        return preferences.globalHotkeysEnabled
    }
    
    var isActuallyWorking: Bool {
        return eventTap != nil
    }
}
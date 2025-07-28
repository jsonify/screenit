import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var menuBarManager: MenuBarManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "camera.viewfinder")
                    .foregroundColor(.primary)
                Text("screenit")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Main menu items
            VStack(alignment: .leading, spacing: 4) {
                MenuItemButton(
                    title: "Capture Area",
                    icon: "viewfinder.circle",
                    shortcut: "⌘⇧4",
                    isEnabled: menuBarManager.canCapture
                ) {
                    menuBarManager.triggerCapture()
                }
                
                MenuItemButton(
                    title: "Show History",
                    icon: "clock.arrow.circlepath",
                    shortcut: "⌘H",
                    isEnabled: true
                ) {
                    menuBarManager.showHistory()
                }
                
                Divider()
                    .padding(.vertical, 2)
                
                MenuItemButton(
                    title: "Preferences...",
                    icon: "gear",
                    shortcut: "⌘,",
                    isEnabled: true
                ) {
                    menuBarManager.showPreferences()
                }
                
                Divider()
                    .padding(.vertical, 2)
                
                MenuItemButton(
                    title: "Quit screenit",
                    icon: "power",
                    shortcut: "⌘Q",
                    isEnabled: true,
                    isDestructive: true
                ) {
                    menuBarManager.quitApp()
                }
            }
            
            // Status indicator
            if menuBarManager.isCapturing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Capturing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            } else if !menuBarManager.canCapture {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Permission required")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Refresh Permissions") {
                        menuBarManager.refreshPermissions()
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .frame(width: 250)
    }
}

struct MenuItemButton: View {
    let title: String
    let icon: String
    let shortcut: String
    let isEnabled: Bool
    let isDestructive: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    init(title: String, icon: String, shortcut: String, isEnabled: Bool, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.shortcut = shortcut
        self.isEnabled = isEnabled
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(foregroundColor)
                
                Text(title)
                    .foregroundColor(foregroundColor)
                    .font(.system(size: 13, weight: .medium))
                
                Spacer()
                
                Text(shortcut)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundValue)
                    .opacity(backgroundOpacity)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovered && isEnabled
            }
            
            if hovered && isEnabled {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .keyboardShortcut(keyboardShortcut, modifiers: keyboardModifiers)
    }
    
    // MARK: - Computed Properties
    
    private var foregroundColor: Color {
        if !isEnabled {
            return .secondary
        } else if isDestructive {
            return .red
        } else {
            return .primary
        }
    }
    
    private var backgroundValue: Color {
        if isHovered {
            return .accentColor
        } else {
            return .clear
        }
    }
    
    private var backgroundOpacity: Double {
        isHovered ? 0.1 : 0.0
    }
    
    private var accessibilityLabel: String {
        "\(title). Keyboard shortcut: \(shortcut)"
    }
    
    private var accessibilityHint: String {
        if !isEnabled && title.contains("Capture") {
            return "Screen recording permission required to use this feature"
        } else if isDestructive {
            return "This action will quit the application"
        } else {
            return "Activate to \(title.lowercased())"
        }
    }
    
    // MARK: - Keyboard Shortcut Parsing
    
    private var keyboardShortcut: KeyEquivalent {
        // Extract the actual key from shortcuts like "⌘⇧4"
        if shortcut.contains("4") {
            return "4"
        } else if shortcut.contains("H") {
            return "h"
        } else if shortcut.contains(",") {
            return ","
        } else if shortcut.contains("Q") {
            return "q"
        }
        return KeyEquivalent("\0") // No shortcut
    }
    
    private var keyboardModifiers: EventModifiers {
        var modifiers: EventModifiers = []
        
        if shortcut.contains("⌘") {
            modifiers.insert(.command)
        }
        if shortcut.contains("⇧") {
            modifiers.insert(.shift)
        }
        if shortcut.contains("⌥") {
            modifiers.insert(.option)
        }
        if shortcut.contains("⌃") {
            modifiers.insert(.control)
        }
        
        return modifiers
    }
}

#Preview {
    MenuBarView()
        .environmentObject(MenuBarManager())
}
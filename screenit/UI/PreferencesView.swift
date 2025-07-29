import SwiftUI
import UniformTypeIdentifiers

struct PreferencesView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @State private var selectedTab = 0
    @State private var showingCustomLocationPicker = false
    @State private var showingResetAlert = false
    @State private var showingImportAlert = false
    @State private var showingExportAlert = false
    @State private var importError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            Picker("Preferences Category", selection: $selectedTab) {
                Text("General").tag(0)
                Text("Capture").tag(1)
                Text("Annotations").tag(2)
                Text("History").tag(3)
                Text("Advanced").tag(4)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Divider()
            
            // Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case 0:
                        GeneralPreferencesView()
                    case 1:
                        CapturePreferencesView()
                    case 2:
                        AnnotationPreferencesView()
                    case 3:
                        HistoryPreferencesView()
                    case 4:
                        AdvancedPreferencesView()
                    default:
                        GeneralPreferencesView()
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Bottom Actions
            HStack {
                Button("Reset to Defaults") {
                    showingResetAlert = true
                }
                .foregroundColor(.red)
                
                Spacer()
                
                // TODO: Re-implement export/import functionality
                Button("Export Settings") {
                    // exportSettings()
                }
                .disabled(true)
                
                Button("Import Settings") {
                    // importSettings()
                }
                .disabled(true)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .alert("Reset Preferences", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                preferencesManager.resetToDefaults()
            }
        } message: {
            Text("This will reset all preferences to their default values. This action cannot be undone.")
        }
        .alert("Import Error", isPresented: $showingImportAlert) {
            Button("OK") { importError = nil }
        } message: {
            Text(importError ?? "Unknown error occurred while importing settings.")
        }
        .fileImporter(
            isPresented: $showingCustomLocationPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleCustomLocationSelection(result)
        }
    }
    
    private func exportSettings() {
        // TODO: Re-implement export functionality
        print("Export settings not yet implemented")
    }
    
    private func importSettings() {
        // TODO: Re-implement import functionality
        print("Import settings not yet implemented")
    }
    
    private func handleCustomLocationSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                preferencesManager.preferences.customSaveLocation = url.path
                preferencesManager.preferences.saveLocation = "custom"
            }
        case .failure(let error):
            print("❌ Failed to select custom location: \(error)")
        }
    }
}

// MARK: - General Preferences

struct GeneralPreferencesView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Show menu bar icon", isOn: Binding(
                    get: { preferencesManager.preferences.showMenuBarIcon },
                    set: { preferencesManager.preferences.showMenuBarIcon = $0 }
                ))
                
                Toggle("Launch at login", isOn: Binding(
                    get: { preferencesManager.preferences.launchAtLogin },
                    set: { preferencesManager.preferences.launchAtLogin = $0 }
                ))
                
                Toggle("Enable sounds", isOn: Binding(
                    get: { preferencesManager.preferences.enableSounds },
                    set: { preferencesManager.preferences.enableSounds = $0 }
                ))
                
                Toggle("Enable notifications", isOn: Binding(
                    get: { preferencesManager.preferences.enableNotifications },
                    set: { preferencesManager.preferences.enableNotifications = $0 }
                ))
            }
            
            Spacer()
        }
    }
}

// MARK: - Capture Preferences

struct CapturePreferencesView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @State private var showingCustomLocationPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Capture")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                // Hotkey setting
                HotkeyCustomizationView()
                
                Divider()
                
                // Save location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Save location:")
                        .fontWeight(.medium)
                    
                    Picker("Save Location", selection: Binding(
                        get: { preferencesManager.preferences.saveLocation },
                        set: { preferencesManager.preferences.saveLocation = $0 }
                    )) {
                        Text("Desktop").tag("desktop")
                        Text("Downloads").tag("downloads")
                        Text("Custom folder").tag("custom")
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    
                    if preferencesManager.preferences.saveLocation == "custom" {
                        HStack {
                            Text(preferencesManager.preferences.customSaveLocation.isEmpty 
                                 ? "No folder selected" 
                                 : URL(fileURLWithPath: preferencesManager.preferences.customSaveLocation).lastPathComponent)
                                .foregroundColor(preferencesManager.preferences.customSaveLocation.isEmpty ? .secondary : .primary)
                            
                            Spacer()
                            
                            Button("Choose...") {
                                chooseCustomLocation()
                            }
                        }
                        .padding(.leading, 20)
                    }
                }
                
                Divider()
                
                // Preview settings
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Show preview window after capture", isOn: Binding(
                        get: { preferencesManager.preferences.showPreviewWindow },
                        set: { preferencesManager.preferences.showPreviewWindow = $0 }
                    ))
                    
                    if preferencesManager.preferences.showPreviewWindow {
                        HStack {
                            Text("Preview duration:")
                            Slider(
                                value: Binding(
                                    get: { preferencesManager.preferences.previewDuration },
                                    set: { preferencesManager.preferences.previewDuration = $0 }
                                ),
                                in: 2...15,
                                step: 1
                            )
                            Text("\(Int(preferencesManager.preferences.previewDuration))s")
                                .frame(width: 30, alignment: .trailing)
                        }
                        .padding(.leading, 20)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func chooseCustomLocation() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Save Location"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.urls.first {
                preferencesManager.preferences.customSaveLocation = url.path
            }
        }
    }
}

// MARK: - Annotation Preferences

struct AnnotationPreferencesView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    
    var body: some View {
        // Debug logging for crash investigation
        let _ = print("🔍 [DEBUG] AnnotationPreferencesView rendering - preferences object valid: \(!preferencesManager.preferences.isDeleted)")
        VStack(alignment: .leading, spacing: 16) {
            Text("Annotations")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Show annotation toolbar", isOn: Binding(
                    get: { 
                        guard !preferencesManager.preferences.isDeleted else { return true }
                        return preferencesManager.preferences.showAnnotationToolbar 
                    },
                    set: { 
                        guard !preferencesManager.preferences.isDeleted else { return }
                        preferencesManager.preferences.showAnnotationToolbar = $0 
                    }
                ))
                
                Divider()
                
                // Default annotation settings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default settings:")
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Arrow thickness:")
                        Slider(
                            value: Binding(
                                get: { 
                                    guard !preferencesManager.preferences.isDeleted else { return 2.0 }
                                    return Double(preferencesManager.preferences.defaultArrowThickness) 
                                },
                                set: { 
                                    guard !preferencesManager.preferences.isDeleted else { return }
                                    preferencesManager.preferences.defaultArrowThickness = Float($0) 
                                }
                            ),
                            in: 1...10,
                            step: 0.5
                        )
                        Text("\(preferencesManager.preferences.isDeleted ? 2.0 : preferencesManager.preferences.defaultArrowThickness, specifier: "%.1f")")
                            .frame(width: 35, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Text size:")
                        Slider(
                            value: Binding(
                                get: { 
                                    guard !preferencesManager.preferences.isDeleted else { return 14.0 }
                                    return Double(preferencesManager.preferences.defaultTextSize) 
                                },
                                set: { 
                                    guard !preferencesManager.preferences.isDeleted else { return }
                                    preferencesManager.preferences.defaultTextSize = Float($0) 
                                }
                            ),
                            in: 10...48,
                            step: 2
                        )
                        Text("\(Int(preferencesManager.preferences.isDeleted ? 14.0 : preferencesManager.preferences.defaultTextSize))")
                            .frame(width: 35, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Default color:")
                        ColorPicker("", selection: Binding(
                            get: { 
                                // Safely get the color with validation
                                guard !preferencesManager.preferences.isDeleted else {
                                    return .red // Default fallback
                                }
                                
                                let colorHex = preferencesManager.preferences.defaultAnnotationColor
                                guard !colorHex.isEmpty else {
                                    return .red // Default fallback for empty string
                                }
                                return Color(hex: colorHex) ?? .red
                            },
                            set: { newColor in
                                // Safely set the color with validation
                                guard !preferencesManager.preferences.isDeleted else { return }
                                preferencesManager.preferences.defaultAnnotationColor = newColor.hexString
                            }
                        ))
                        .frame(width: 50)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - History Preferences

struct HistoryPreferencesView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("History")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Auto-save captures to history", isOn: Binding(
                    get: { preferencesManager.preferences.autoSaveToHistory },
                    set: { preferencesManager.preferences.autoSaveToHistory = $0 }
                ))
                
                Toggle("Enable history thumbnails", isOn: Binding(
                    get: { preferencesManager.preferences.enableHistoryThumbnails },
                    set: { preferencesManager.preferences.enableHistoryThumbnails = $0 }
                ))
                
                Divider()
                
                HStack {
                    Text("Keep last")
                    TextField("", value: Binding(
                        get: { preferencesManager.preferences.historyRetentionLimit },
                        set: { preferencesManager.preferences.historyRetentionLimit = max(1, $0) }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    
                    Text("captures")
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Advanced Preferences

struct AdvancedPreferencesView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable high DPI capture", isOn: Binding(
                    get: { preferencesManager.preferences.enableHighDPICapture },
                    set: { preferencesManager.preferences.enableHighDPICapture = $0 }
                ))
                
                HStack {
                    Text("Compression quality:")
                    Slider(
                        value: Binding(
                            get: { preferencesManager.preferences.compressionQuality },
                            set: { preferencesManager.preferences.compressionQuality = $0 }
                        ),
                        in: 0.1...1.0,
                        step: 0.1
                    )
                    Text("\(preferencesManager.preferences.compressionQuality, specifier: "%.1f")")
                        .frame(width: 35, alignment: .trailing)
                }
                
                HStack {
                    Text("Max image size:")
                    TextField("", value: Binding(
                        get: { preferencesManager.preferences.maxImageSize },
                        set: { preferencesManager.preferences.maxImageSize = max(100, $0) }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    
                    Text("pixels")
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Color Extensions

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var hexString: String {
        guard let cgColor = self.cgColor,
              let components = cgColor.components,
              components.count >= 3 else {
            return "#FF0000" // Default to red if conversion fails
        }
        
        let r = Int((components[0] * 255).rounded())
        let g = Int((components[1] * 255).rounded())
        let b = Int((components[2] * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

#Preview {
    PreferencesView()
        .environmentObject(PreferencesManager.shared)
}

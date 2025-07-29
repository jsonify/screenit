import SwiftUI
import Combine
import Carbon

struct HotkeyCustomizationView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @StateObject private var hotkeyRecorder = HotkeyRecorder()
    @State private var customHotkeyText = ""
    @State private var showingRecommendations = false
    @State private var validationResult: HotkeyValidationResult = .valid
    
    private let recommendedHotkeys = HotkeyParser.getRecommendedHotkeys()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Capture hotkey:")
                    .fontWeight(.medium)
                
                Spacer()
                
                // Current hotkey display
                HStack {
                    Text(preferencesManager.captureHotkeyDisplayString)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                        .font(.system(.body, design: .monospaced))
                    
                    Button("Change...") {
                        customHotkeyText = preferencesManager.captureHotkeyString
                        showingRecommendations = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // Show validation status if there are issues
            if let message = validationResult.message {
                HStack {
                    Image(systemName: validationIconName)
                        .foregroundColor(validationColor)
                    Text(message)
                        .foregroundColor(validationColor)
                        .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showingRecommendations) {
            HotkeyCustomizationSheet(
                currentHotkey: preferencesManager.captureHotkeyString,
                onHotkeyChanged: { newHotkey in
                    let success = preferencesManager.updateCaptureHotkey(newHotkey)
                    if !success {
                        // Handle error - could show an alert or update validation state
                        print("Failed to update hotkey to: \(newHotkey)")
                    }
                }
            )
            .environmentObject(preferencesManager)
        }
        .onAppear {
            validateCurrentHotkey()
        }
        .onChange(of: preferencesManager.captureHotkeyString) {
            validateCurrentHotkey()
        }
    }
    
    private var validationIconName: String {
        switch validationResult {
        case .valid:
            return "checkmark.circle.fill"
        case .invalid:
            return "xmark.circle.fill"
        case .systemConflict:
            return "exclamationmark.triangle.fill"
        case .notRecommended:
            return "info.circle.fill"
        }
    }
    
    private var validationColor: Color {
        switch validationResult {
        case .valid:
            return .green
        case .invalid, .systemConflict:
            return .red
        case .notRecommended:
            return .orange
        }
    }
    
    private func validateCurrentHotkey() {
        validationResult = preferencesManager.validateHotkeyString(preferencesManager.captureHotkeyString)
    }
}

// MARK: - Hotkey Customization Sheet

struct HotkeyCustomizationSheet: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @Environment(\.dismiss) private var dismiss
    
    let currentHotkey: String
    let onHotkeyChanged: (String) -> Void
    
    @State private var selectedMethod = 0 // 0 = recorder, 1 = text input, 2 = presets
    @State private var customText = ""
    @State private var validationResult: HotkeyValidationResult = .valid
    @StateObject private var recorder = HotkeyRecorder()
    
    private let recommendedHotkeys = HotkeyParser.getRecommendedHotkeys()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Customize Hotkey")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // Method selection
            Picker("Input Method", selection: $selectedMethod) {
                Text("Record Key").tag(0)
                Text("Type Combination").tag(1)
                Text("Choose Preset").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Content based on selected method
            switch selectedMethod {
            case 0:
                RecorderMethodView(recorder: recorder, onHotkeyRecorded: handleRecordedHotkey)
            case 1:
                TextInputMethodView(
                    customText: $customText,
                    validationResult: $validationResult,
                    onValidate: validateTextInput
                )
            case 2:
                PresetMethodView(
                    recommendedHotkeys: recommendedHotkeys,
                    currentHotkey: currentHotkey,
                    onPresetSelected: handlePresetSelected
                )
            default:
                EmptyView()
            }
            
            Spacer()
            
            Divider()
            
            // Bottom actions
            HStack {
                Button("Reset to Default") {
                    preferencesManager.resetCaptureHotkeyToDefault()
                    customText = preferencesManager.captureHotkeyString
                    validateTextInput()
                }
                .foregroundColor(.orange)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Apply") {
                    applyHotkey()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canApply)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .onAppear {
            customText = currentHotkey
            validateTextInput()
        }
    }
    
    private var canApply: Bool {
        switch selectedMethod {
        case 0:
            return recorder.recordedHotkey != nil
        case 1:
            return validationResult.isValid
        case 2:
            return true
        default:
            return false
        }
    }
    
    private func handleRecordedHotkey(_ hotkey: String) {
        print("✅ [DEBUG] Recorded hotkey: \(hotkey)")
    }
    
    private func handlePresetSelected(_ hotkey: String) {
        customText = hotkey
        validationResult = HotkeyParser.validateHotkey(hotkey)
    }
    
    private func validateTextInput() {
        validationResult = HotkeyParser.validateHotkey(customText)
    }
    
    private func applyHotkey() {
        let hotkeyToApply: String
        
        switch selectedMethod {
        case 0:
            guard let recordedHotkey = recorder.recordedHotkey else { return }
            hotkeyToApply = recordedHotkey
        case 1, 2:
            hotkeyToApply = customText
        default:
            return
        }
        
        // Validate one more time
        let validation = HotkeyParser.validateHotkey(hotkeyToApply)
        guard validation.isValid else {
            print("❌ [DEBUG] Cannot apply invalid hotkey: \(hotkeyToApply)")
            return
        }
        
        onHotkeyChanged(hotkeyToApply)
        dismiss()
    }
}

// MARK: - Method Views

struct RecorderMethodView: View {
    @ObservedObject var recorder: HotkeyRecorder
    let onHotkeyRecorded: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Press the key combination you want to use")
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(recorder.isRecording ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(recorder.isRecording ? Color.blue : Color.gray, lineWidth: 2)
                    )
                
                VStack {
                    if recorder.isRecording {
                        Text("Recording...")
                            .foregroundColor(.blue)
                            .font(.headline)
                        Text("Press any key combination")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else if let hotkey = recorder.recordedHotkey {
                        Text(HotkeyParser.formatHotkeyString(hotkey))
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.semibold)
                    } else {
                        Text("Click to record hotkey")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onTapGesture {
                // Safety check to prevent actions on deallocating recorder
                guard !recorder.isCleaningUpPublic else { return }
                
                if recorder.isRecording {
                    recorder.stopRecording()
                } else {
                    recorder.startRecording()
                }
            }
            
            if recorder.isRecording {
                Button("Stop Recording") {
                    guard !recorder.isCleaningUpPublic else { return }
                    recorder.stopRecording()
                }
                .foregroundColor(.red)
            } else {
                Button(recorder.recordedHotkey == nil ? "Start Recording" : "Record Again") {
                    guard !recorder.isCleaningUpPublic else { return }
                    recorder.startRecording()
                }
            }
        }
        .padding()
        .onChange(of: recorder.recordedHotkey) { _, hotkey in
            if let hotkey = hotkey {
                onHotkeyRecorded(hotkey)
            }
        }
    }
}

struct TextInputMethodView: View {
    @Binding var customText: String
    @Binding var validationResult: HotkeyValidationResult
    let onValidate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter hotkey combination")
                .foregroundColor(.secondary)
            
            TextField("e.g., cmd+shift+4", text: $customText)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onChange(of: customText) {
                    onValidate()
                }
            
            if let message = validationResult.message {
                HStack {
                    Image(systemName: validationIconName)
                        .foregroundColor(validationColor)
                    Text(message)
                        .foregroundColor(validationColor)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Format examples:")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("• cmd+shift+4")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• ctrl+shift+s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• cmd+f6")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var validationIconName: String {
        switch validationResult {
        case .valid:
            return "checkmark.circle.fill"
        case .invalid:
            return "xmark.circle.fill"
        case .systemConflict:
            return "exclamationmark.triangle.fill"
        case .notRecommended:
            return "info.circle.fill"
        }
    }
    
    private var validationColor: Color {
        switch validationResult {
        case .valid:
            return .green
        case .invalid, .systemConflict:
            return .red
        case .notRecommended:
            return .orange
        }
    }
}

struct PresetMethodView: View {
    let recommendedHotkeys: [String]
    let currentHotkey: String
    let onPresetSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose from recommended combinations")
                .foregroundColor(.secondary)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(recommendedHotkeys, id: \.self) { hotkey in
                        Button(action: {
                            onPresetSelected(hotkey)
                        }) {
                            HStack {
                                Text(HotkeyParser.formatHotkeyString(hotkey))
                                    .font(.system(.body, design: .monospaced))
                                if hotkey == currentHotkey {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(hotkey == currentHotkey ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding()
    }
}

// MARK: - Hotkey Recorder

@MainActor
class HotkeyRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var recordedHotkey: String?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isCleaningUp = false
    
    var isCleaningUpPublic: Bool {
        isCleaningUp
    }
    
    func startRecording() {
        guard !isRecording && !isCleaningUp else { return }
        
        print("🎤 [DEBUG] Starting hotkey recording...")
        isRecording = true
        recordedHotkey = nil
        
        // Create event tap for key events
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        // Store a weak reference to avoid retain cycle
        let weakSelf = Unmanaged.passUnretained(self)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                
                // Use unretained reference to avoid retain cycle
                let recorder = Unmanaged<HotkeyRecorder>.fromOpaque(refcon).takeUnretainedValue()
                
                // Safety check: ensure recorder is still valid
                guard !recorder.isCleaningUp else {
                    return nil // Consume event but don't process
                }
                
                recorder.handleKeyEvent(type: type, event: event)
                return nil // Consume the event
            },
            userInfo: weakSelf.toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("❌ [DEBUG] Failed to create event tap - accessibility permissions may be needed")
            isRecording = false
            isCleaningUp = false
            return
        }
        
        // Add to run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("✅ [DEBUG] Hotkey recording started")
    }
    
    nonisolated func stopRecording() {
        Task { @MainActor in
            guard isRecording && !isCleaningUp else { return }
            
            print("🛑 [DEBUG] Stopping hotkey recording...")
            cleanupImmediately()
        }
    }
    
    nonisolated private func handleKeyEvent(type: CGEventType, event: CGEvent) {
        Task { @MainActor in
            guard isRecording && !isCleaningUp else { return }
        
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            // Convert flags to modifier string
            var modifiers: [String] = []
            
            if flags.contains(.maskCommand) {
                modifiers.append("cmd")
            }
            if flags.contains(.maskShift) {
                modifiers.append("shift")
            }
            if flags.contains(.maskAlternate) {
                modifiers.append("option")
            }
            if flags.contains(.maskControl) {
                modifiers.append("ctrl")
            }
            
            // Only proceed if we have modifiers (required for global hotkeys)
            guard !modifiers.isEmpty else { return }
            
            // Convert keycode to string
            if let keyString = keyCodeToString(UInt32(keyCode)) {
                let hotkeyString = (modifiers + [keyString]).joined(separator: "+")
                
                print("🎤 [DEBUG] Recorded: \(hotkeyString)")
                recordedHotkey = hotkeyString
                
                // Stop recording after successful capture
                Task { @MainActor in
                    guard isRecording && !isCleaningUp else { return }
                    cleanupImmediately()
                }
            }
        }
        }
    }
    
    private func keyCodeToString(_ keyCode: UInt32) -> String? {
        // Use HotkeyParser's comprehensive key mapping
        return HotkeyParser.keyCodeToString(keyCode)
    }
    
    deinit {
        print("🗑️ [DEBUG] HotkeyRecorder deinit called")
        isCleaningUp = true
        
        // Clean up event tap synchronously to avoid retain cycles
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        // Clean up run loop source synchronously
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
    
    private func cleanupImmediately() {
        print("🧹 [DEBUG] Performing immediate cleanup")
        isRecording = false
        
        // Clean up event tap synchronously
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
        
        // Clean up run loop source synchronously
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        
        print("✅ [DEBUG] Immediate cleanup completed")
    }
}

#Preview {
    HotkeyCustomizationView()
        .environmentObject(PreferencesManager.shared)
}
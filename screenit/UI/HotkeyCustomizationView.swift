import SwiftUI
import Combine

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
                    Text(preferencesManager.preferences.captureHotkey.hotkeyDisplayName)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                        .font(.system(.body, design: .monospaced))
                    
                    Button("Change...") {
                        customHotkeyText = preferencesManager.preferences.captureHotkey
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
                currentHotkey: preferencesManager.preferences.captureHotkey,
                onHotkeyChanged: { newHotkey in
                    preferencesManager.preferences.captureHotkey = newHotkey
                }
            )
            .environmentObject(preferencesManager)
        }
        .onAppear {
            validateCurrentHotkey()
        }
        .onChange(of: preferencesManager.preferences.captureHotkey) { _ in
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
        validationResult = HotkeyParser.validateHotkey(preferencesManager.preferences.captureHotkey)
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
                    handlePresetSelected("cmd+shift+4")
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
                if recorder.isRecording {
                    recorder.stopRecording()
                } else {
                    recorder.startRecording()
                }
            }
            
            if recorder.isRecording {
                Button("Stop Recording") {
                    recorder.stopRecording()
                }
                .foregroundColor(.red)
            } else {
                Button(recorder.recordedHotkey == nil ? "Start Recording" : "Record Again") {
                    recorder.startRecording()
                }
            }
        }
        .padding()
        .onChange(of: recorder.recordedHotkey) { hotkey in
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
                .onChange(of: customText) { _ in
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
    
    func startRecording() {
        guard !isRecording else { return }
        
        print("🎤 [DEBUG] Starting hotkey recording...")
        isRecording = true
        recordedHotkey = nil
        
        // Create event tap for key events
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let recorder = Unmanaged<HotkeyRecorder>.fromOpaque(refcon).takeUnretainedValue()
                recorder.handleKeyEvent(type: type, event: event)
                return nil // Consume the event
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("❌ [DEBUG] Failed to create event tap")
            isRecording = false
            return
        }
        
        // Add to run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("✅ [DEBUG] Hotkey recording started")
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        print("🛑 [DEBUG] Stopping hotkey recording...")
        isRecording = false
        
        // Clean up event tap
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        
        print("✅ [DEBUG] Hotkey recording stopped")
    }
    
    private func handleKeyEvent(type: CGEventType, event: CGEvent) {
        guard isRecording else { return }
        
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
                    stopRecording()
                }
            }
        }
    }
    
    private func keyCodeToString(_ keyCode: UInt32) -> String? {
        // This is a simplified mapping - you'd want to use the full keyCodeMap from HotkeyParser
        switch keyCode {
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
        case 0: return "a"
        case 11: return "b"
        case 8: return "c"
        case 2: return "d"
        case 14: return "e"
        case 3: return "f"
        case 5: return "g"
        case 4: return "h"
        case 34: return "i"
        case 38: return "j"
        case 40: return "k"
        case 37: return "l"
        case 46: return "m"
        case 45: return "n"
        case 31: return "o"
        case 35: return "p"
        case 12: return "q"
        case 15: return "r"
        case 1: return "s"
        case 17: return "t"
        case 32: return "u"
        case 9: return "v"
        case 13: return "w"
        case 7: return "x"
        case 16: return "y"
        case 6: return "z"
        case 49: return "space"
        case 36: return "return"
        case 53: return "escape"
        case 51: return "delete"
        default: return nil
        }
    }
    
    deinit {
        Task { @MainActor in
            stopRecording()
        }
    }
}

#Preview {
    HotkeyCustomizationView()
        .environmentObject(PreferencesManager.shared)
}
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
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var captureAnimation: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Press the key combination you want to use")
                .foregroundColor(.secondary)
            
            // Enhanced Visual Recording Area
            ZStack {
                // Background with animated border
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundFill)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: borderWidth)
                            .scaleEffect(recorder.isRecording ? pulseScale : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recorder.isRecording)
                    )
                
                // Content with state-based display
                VStack(spacing: 8) {
                    // Status Icon
                    Image(systemName: statusIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(statusIconColor)
                        .scaleEffect(captureAnimation ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: captureAnimation)
                    
                    // Status Text
                    if recorder.isRecording {
                        VStack(spacing: 4) {
                            Text("Recording...")
                                .foregroundColor(.blue)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Press any key combination")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    } else if let error = recorder.lastError {
                        VStack(spacing: 4) {
                            Text("Error")
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    } else if let hotkey = recorder.recordedHotkey {
                        VStack(spacing: 4) {
                            Text("Captured")
                                .foregroundColor(.green)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(HotkeyParser.formatHotkeyString(hotkey))
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    } else {
                        VStack(spacing: 4) {
                            Text("Ready")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Click to record hotkey")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .onTapGesture {
                // Safety check to prevent actions on deallocating recorder
                guard !recorder.isCleaningUpPublic else { return }
                
                if recorder.isRecording {
                    recorder.stopRecording()
                } else {
                    // Clear any previous error before starting
                    if recorder.lastError != nil {
                        recorder.lastError = nil
                    }
                    recorder.startRecording()
                }
            }
            .contentShape(Rectangle()) // Make entire area tappable
            
            // Action Button with enhanced styling
            if recorder.isRecording {
                Button(action: {
                    guard !recorder.isCleaningUpPublic else { return }
                    recorder.stopRecording()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Recording")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: {
                    guard !recorder.isCleaningUpPublic else { return }
                    // Clear any previous error before starting
                    if recorder.lastError != nil {
                        recorder.lastError = nil
                    }
                    recorder.startRecording()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: recorder.recordedHotkey == nil ? "record.circle" : "arrow.clockwise.circle")
                        Text(recorder.recordedHotkey == nil ? "Start Recording" : "Record Again")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .onChange(of: recorder.recordedHotkey) { _, hotkey in
            if let hotkey = hotkey {
                // Trigger capture animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    captureAnimation = true
                }
                // Reset animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        captureAnimation = false
                    }
                }
                onHotkeyRecorded(hotkey)
            }
        }
        .onChange(of: recorder.isRecording) { _, isRecording in
            if isRecording {
                // Start pulse animation
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            } else {
                // Stop pulse animation
                withAnimation(.easeOut(duration: 0.3)) {
                    pulseScale = 1.0
                }
            }
        }
    }
    
    // MARK: - Computed Properties for Visual States
    
    private var backgroundFill: some ShapeStyle {
        if recorder.isRecording {
            return AnyShapeStyle(Color.blue.opacity(0.08))
        } else if recorder.lastError != nil {
            return AnyShapeStyle(Color.red.opacity(0.06))
        } else if recorder.recordedHotkey != nil {
            return AnyShapeStyle(Color.green.opacity(0.06))
        } else {
            return AnyShapeStyle(Color.gray.opacity(0.05))
        }
    }
    
    private var borderColor: Color {
        if recorder.isRecording {
            return .blue
        } else if recorder.lastError != nil {
            return .red
        } else if recorder.recordedHotkey != nil {
            return .green
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        if recorder.isRecording || recorder.lastError != nil {
            return 2.5
        } else {
            return 1.5
        }
    }
    
    private var statusIcon: String {
        if recorder.isRecording {
            return "waveform"
        } else if recorder.lastError != nil {
            return "exclamationmark.triangle.fill"
        } else if recorder.recordedHotkey != nil {
            return "checkmark.circle.fill"
        } else {
            return "hand.tap"
        }
    }
    
    private var statusIconColor: Color {
        if recorder.isRecording {
            return .blue
        } else if recorder.lastError != nil {
            return .red
        } else if recorder.recordedHotkey != nil {
            return .green
        } else {
            return .secondary
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

/// Enhanced hotkey recorder with improved event monitoring and cleanup
@MainActor
class HotkeyRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var recordedHotkey: String?
    @Published var lastError: String?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isCleaningUp = false
    private var recordingStartTime: Date?
    
    // Enhanced error tracking and timeout handling
    private let maxRecordingDuration: TimeInterval = 30.0 // 30 second timeout
    private var recordingTimeoutTask: Task<Void, Never>?
    
    var isCleaningUpPublic: Bool {
        isCleaningUp
    }
    
    /// Current recording duration in seconds
    var recordingDuration: TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func startRecording() {
        guard !isRecording && !isCleaningUp else { 
            print("⚠️ [DEBUG] Cannot start recording: already recording (\(isRecording)) or cleaning up (\(isCleaningUp))")
            return 
        }
        
        // Clear any previous errors
        lastError = nil
        recordedHotkey = nil
        recordingStartTime = Date()
        
        print("🎤 [DEBUG] Starting enhanced hotkey recording...")
        
        // Check accessibility permissions first
        guard checkAccessibilityPermissions() else {
            handleRecordingError("Accessibility permissions required. Please enable in System Preferences > Security & Privacy > Privacy > Accessibility")
            return
        }
        
        isRecording = true
        
        // Set up recording timeout
        setupRecordingTimeout()
        
        // Create event tap with enhanced error handling
        guard createEventTap() else {
            handleRecordingError("Failed to create event monitoring. Please try again.")
            return
        }
        
        print("✅ [DEBUG] Enhanced hotkey recording started")
    }
    
    /// Check if accessibility permissions are available
    private func checkAccessibilityPermissions() -> Bool {
        // Try to create a test event tap to check permissions
        let testTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { _, _, event, _ in return Unmanaged.passUnretained(event) },
            userInfo: nil
        )
        
        defer {
            if let testTap = testTap {
                CFMachPortInvalidate(testTap)
            }
        }
        
        return testTap != nil
    }
    
    /// Set up recording timeout to prevent infinite recording
    private func setupRecordingTimeout() {
        recordingTimeoutTask?.cancel()
        recordingTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self?.maxRecordingDuration ?? 30.0 * 1_000_000_000))
            
            await MainActor.run { [weak self] in
                guard let self = self, self.isRecording else { return }
                print("⏰ [DEBUG] Recording timeout reached, stopping...")
                self.handleRecordingError("Recording timeout - please try again")
                self.cleanupImmediately()
            }
        }
    }
    
    /// Create and configure the event tap
    private func createEventTap() -> Bool {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        // Store a weak reference to avoid retain cycle
        let weakSelf = Unmanaged.passUnretained(self)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { 
                    print("⚠️ [DEBUG] Event callback received with nil refcon")
                    return Unmanaged.passUnretained(event) 
                }
                
                // Use unretained reference to avoid retain cycle
                let recorder = Unmanaged<HotkeyRecorder>.fromOpaque(refcon).takeUnretainedValue()
                
                // Safety check: ensure recorder is still valid and recording
                guard !recorder.isCleaningUp && recorder.isRecording else {
                    return nil // Consume event but don't process
                }
                
                recorder.handleKeyEvent(type: type, event: event)
                return nil // Consume the event
            },
            userInfo: weakSelf.toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("❌ [DEBUG] Failed to create event tap")
            return false
        }
        
        // Add to run loop with error checking
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let runLoopSource = runLoopSource else {
            print("❌ [DEBUG] Failed to create run loop source")
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
            return false
        }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        // Verify the event tap is enabled
        if !CGEvent.tapIsEnabled(tap: eventTap) {
            print("❌ [DEBUG] Event tap failed to enable")
            return false
        }
        
        return true
    }
    
    /// Handle recording errors with user-friendly messages
    private func handleRecordingError(_ message: String) {
        print("❌ [DEBUG] Recording error: \(message)")
        lastError = message
        isRecording = false
        recordingStartTime = nil
        recordingTimeoutTask?.cancel()
        recordingTimeoutTask = nil
    }
    
    nonisolated func stopRecording() {
        Task { @MainActor in
            guard isRecording && !isCleaningUp else { 
                print("⚠️ [DEBUG] Cannot stop recording: not recording (\(!isRecording)) or cleaning up (\(isCleaningUp))")
                return 
            }
            
            print("🛑 [DEBUG] Stopping enhanced hotkey recording...")
            
            // Cancel timeout task
            recordingTimeoutTask?.cancel()
            recordingTimeoutTask = nil
            
            // Clear recording start time
            recordingStartTime = nil
            
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
        print("🗑️ [DEBUG] Enhanced HotkeyRecorder deinit called")
        isCleaningUp = true
        
        // Cancel any pending timeout task
        recordingTimeoutTask?.cancel()
        recordingTimeoutTask = nil
        
        // Clean up event tap synchronously to avoid retain cycles
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        // Clean up run loop source synchronously
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        print("✅ [DEBUG] Enhanced HotkeyRecorder cleanup completed")
    }
    
    private func cleanupImmediately() {
        print("🧹 [DEBUG] Performing enhanced immediate cleanup")
        isRecording = false
        recordingStartTime = nil
        
        // Cancel timeout task
        recordingTimeoutTask?.cancel()
        recordingTimeoutTask = nil
        
        // Clean up event tap synchronously with error handling
        if let eventTap = eventTap {
            let wasEnabled = CGEvent.tapIsEnabled(tap: eventTap)
            if wasEnabled {
                CGEvent.tapEnable(tap: eventTap, enable: false)
            }
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
            print("🧹 [DEBUG] Event tap cleaned up (was enabled: \(wasEnabled))")
        }
        
        // Clean up run loop source synchronously
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
            print("🧹 [DEBUG] Run loop source cleaned up")
        }
        
        print("✅ [DEBUG] Enhanced immediate cleanup completed")
    }
}

#Preview {
    HotkeyCustomizationView()
        .environmentObject(PreferencesManager.shared)
}
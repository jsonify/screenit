import SwiftUI

// MARK: - Text Input View

struct TextInputView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let position: CGPoint
    let fontSize: Double
    let fontWeight: Font.Weight
    let color: Color
    let backgroundColor: Color?
    let onComplete: (String) -> Void
    let onCancel: () -> Void
    
    @State private var textFieldWidth: CGFloat = 200
    @State private var textFieldHeight: CGFloat = 30
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        if isEditing {
            ZStack {
                // Background if specified
                if let backgroundColor = backgroundColor {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(backgroundColor)
                        .frame(width: textFieldWidth + 8, height: textFieldHeight + 4)
                }
                
                // Text input field
                TextField("Enter text...", text: $text, axis: .vertical)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundColor(color)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1...10)
                    .focused($isTextFieldFocused)
                    .frame(width: textFieldWidth, height: textFieldHeight)
                    .onSubmit {
                        completeEditing()
                    }
                    .onKeyPress(.escape) {
                        cancelEditing()
                        return .handled
                    }
                    .onChange(of: text) { _, newValue in
                        updateFieldSize(for: newValue)
                    }
            }
            .position(x: position.x + textFieldWidth/2, y: position.y + textFieldHeight/2)
            .onAppear {
                // Auto-focus when the view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
                updateFieldSize(for: text)
            }
        }
    }
    
    private func updateFieldSize(for text: String) {
        // Calculate approximate text size
        let characterWidth = fontSize * 0.6
        let lineHeight = fontSize * 1.2
        
        let lines = text.components(separatedBy: .newlines)
        let maxLineLength = lines.map { $0.count }.max() ?? 0
        
        // Minimum width and height
        let minWidth: CGFloat = 100
        let minHeight: CGFloat = 24
        
        textFieldWidth = max(minWidth, CGFloat(maxLineLength) * characterWidth + 20)
        textFieldHeight = max(minHeight, CGFloat(lines.count) * lineHeight + 8)
    }
    
    private func completeEditing() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            onComplete(trimmedText)
        } else {
            onCancel()
        }
    }
    
    private func cancelEditing() {
        onCancel()
    }
}

// MARK: - Text Input View Modifiers

extension View {
    func textInput(
        text: Binding<String>,
        isEditing: Binding<Bool>,
        at position: CGPoint,
        fontSize: Double = 16,
        fontWeight: Font.Weight = .regular,
        color: Color = .black,
        backgroundColor: Color? = nil,
        onComplete: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        self.overlay(
            TextInputView(
                text: text,
                isEditing: isEditing,
                position: position,
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: color,
                backgroundColor: backgroundColor,
                onComplete: onComplete,
                onCancel: onCancel
            )
        )
    }
}

// MARK: - Text Input Configuration

struct TextInputConfiguration {
    var fontSize: Double = 16
    var fontWeight: Font.Weight = .regular
    var color: Color = .black
    var backgroundColor: Color? = nil
    var placeholder: String = "Enter text..."
    var multiline: Bool = true
    var maxLines: Int = 10
    
    init() {}
    
    @MainActor
    init(from toolState: AnnotationToolState) {
        self.fontSize = toolState.fontSize
        self.fontWeight = toolState.fontWeight
        self.color = toolState.color
        self.backgroundColor = nil // TODO: Add background color support to AnnotationToolState
    }
}

// MARK: - Text Input State

@MainActor
class TextInputState: ObservableObject {
    @Published var text: String = ""
    @Published var isEditing: Bool = false
    @Published var position: CGPoint = .zero
    @Published var configuration: TextInputConfiguration = TextInputConfiguration()
    
    func startEditing(at point: CGPoint, with config: TextInputConfiguration = TextInputConfiguration()) {
        position = point
        configuration = config
        text = ""
        isEditing = true
    }
    
    func finishEditing() -> String? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditing = false
        text = ""
        return trimmedText.isEmpty ? nil : trimmedText
    }
    
    func cancelEditing() {
        isEditing = false
        text = ""
    }
    
    func updateText(_ newText: String) {
        text = newText
    }
}
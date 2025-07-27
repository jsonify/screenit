import Foundation
import SwiftUI
import Combine

// MARK: - Text Tool

@MainActor
class TextTool: BaseAnnotationTool {
    
    // MARK: - Properties
    
    @Published var textInputState: TextInputState = TextInputState()
    private var cancellables = Set<AnyCancellable>()
    private var currentConfiguration: TextInputConfiguration = TextInputConfiguration()
    
    // Legacy properties for compatibility
    private var isEditingText: Bool {
        textInputState.isEditing
    }
    
    private var textInput: String {
        textInputState.text
    }
    
    // MARK: - Initialization
    
    init() {
        super.init(type: .text)
        setupTextInputObservation()
    }
    
    // MARK: - Configuration
    
    override func configure(with state: AnnotationToolState) {
        super.configure(with: state)
        currentConfiguration = TextInputConfiguration(from: state)
    }
    
    // MARK: - Drawing Lifecycle
    
    override func handleDrawStart(_ point: CGPoint, state: AnnotationToolState) {
        startPoint = point
        currentPoint = point
        isDrawing = true
        
        // Start text editing with current configuration
        beginTextEditing(at: point, state: state)
    }
    
    override func handleDrawUpdate(_ point: CGPoint, state: AnnotationToolState) {
        // Text tool doesn't need draw updates during creation
        // Position is set at start and doesn't change during creation
    }
    
    override func handleDrawEnd(_ point: CGPoint, state: AnnotationToolState) -> Annotation? {
        // For text tool, we don't create annotation on draw end
        // Text editing continues until user completes or cancels
        return nil
    }
    
    // MARK: - Text Editing
    
    private func beginTextEditing(at point: CGPoint, state: AnnotationToolState) {
        currentConfiguration = TextInputConfiguration(from: state)
        textInputState.startEditing(at: point, with: currentConfiguration)
    }
    
    func updateTextInput(_ text: String) {
        textInputState.updateText(text)
    }
    
    func finishTextEditing() -> Annotation? {
        guard let text = textInputState.finishEditing(),
              let point = startPoint else { 
            reset()
            return nil 
        }
        
        let annotation = createTextAnnotation(at: point, text: text, state: getCurrentToolState())
        reset()
        return annotation
    }
    
    func cancelTextEditing() {
        textInputState.cancelEditing()
        reset()
    }
    
    private func reset() {
        isDrawing = false
        startPoint = nil
        currentPoint = nil
    }
    
    private func getCurrentToolState() -> AnnotationToolState {
        let state = AnnotationToolState()
        state.fontSize = currentConfiguration.fontSize
        state.fontWeight = currentConfiguration.fontWeight
        state.color = currentConfiguration.color
        return state
    }
    
    // MARK: - Text Input Observation
    
    private func setupTextInputObservation() {
        // Observe text input completion
        textInputState.$isEditing
            .sink { [weak self] isEditing in
                if !isEditing && self?.textInputState.text.isEmpty == false {
                    // Text editing completed - this could trigger annotation creation
                    // The actual annotation creation is handled by the canvas/engine
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Annotation Creation
    
    override func createAnnotation(from startPoint: CGPoint, to endPoint: CGPoint, state: AnnotationToolState) -> Annotation? {
        return createTextAnnotation(at: startPoint, text: textInput, state: state)
    }
    
    private func createTextAnnotation(at point: CGPoint, text: String, state: AnnotationToolState) -> Annotation? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        var properties = state.textProperties
        properties.text = text
        
        // Calculate text size with better accuracy
        let textSize = calculateTextSize(
            text: text, 
            fontSize: properties.fontSize, 
            fontWeight: properties.fontWeight
        )
        let geometry = TextGeometry(position: point, size: textSize)
        
        return Annotation(
            type: .text,
            properties: properties,
            geometry: geometry
        )
    }
    
    // MARK: - Font and Color Customization
    
    func updateFontSize(_ fontSize: Double) {
        currentConfiguration.fontSize = fontSize
        // Update the tool state if currently editing
        if textInputState.isEditing {
            textInputState.configuration.fontSize = fontSize
        }
    }
    
    func updateFontWeight(_ fontWeight: Font.Weight) {
        currentConfiguration.fontWeight = fontWeight
        if textInputState.isEditing {
            textInputState.configuration.fontWeight = fontWeight
        }
    }
    
    func updateColor(_ color: Color) {
        currentConfiguration.color = color
        if textInputState.isEditing {
            textInputState.configuration.color = color
        }
    }
    
    func updateBackgroundColor(_ backgroundColor: Color?) {
        currentConfiguration.backgroundColor = backgroundColor
        if textInputState.isEditing {
            textInputState.configuration.backgroundColor = backgroundColor
        }
    }
    
    // MARK: - Text Configuration Presets
    
    func applyPreset(_ preset: TextPreset) {
        currentConfiguration.fontSize = preset.fontSize
        currentConfiguration.fontWeight = preset.fontWeight
        currentConfiguration.color = preset.color
        currentConfiguration.backgroundColor = preset.backgroundColor
        
        if textInputState.isEditing {
            textInputState.configuration = currentConfiguration
        }
    }
    
    // MARK: - Rendering
    
    override func render(_ annotation: Annotation, in context: GraphicsContext) {
        guard let properties = annotation.properties as? TextProperties,
              let geometry = annotation.geometry as? TextGeometry else { return }
        
        let text = properties.text
        let position = geometry.position
        
        // Create text attributes
        let font = Font.system(size: properties.fontSize, weight: properties.fontWeight)
        
        // Draw background if specified
        if let backgroundColor = properties.backgroundColor {
            let backgroundRect = CGRect(
                origin: position,
                size: geometry.size
            ).insetBy(dx: -4, dy: -2)
            
            context.fill(
                Path(backgroundRect),
                with: .color(backgroundColor)
            )
        }
        
        // Draw text
        context.draw(
            Text(text)
                .font(font)
                .foregroundColor(properties.color),
            at: position,
            anchor: .topLeading
        )
    }
    
    // MARK: - Hit Testing
    
    override func hitTest(_ point: CGPoint, annotation: Annotation) -> Bool {
        guard let geometry = annotation.geometry as? TextGeometry else { return false }
        
        let bounds = geometry.bounds
        let expandedBounds = expandedBounds(bounds, by: 4.0)
        return expandedBounds.contains(point)
    }
    
    // MARK: - Private Methods
    
    private func calculateTextSize(text: String, fontSize: Double, fontWeight: Font.Weight) -> CGSize {
        // More accurate text size calculation using NSString
        let font = NSFont.systemFont(ofSize: fontSize, weight: fontWeight.nsWeight)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let boundingRect = attributedString.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        
        // Add some padding for better visual appearance
        return CGSize(
            width: ceil(boundingRect.width) + 4,
            height: ceil(boundingRect.height) + 2
        )
    }
}

// MARK: - Text Preset Configuration

struct TextPreset {
    let name: String
    let fontSize: Double
    let fontWeight: Font.Weight
    let color: Color
    let backgroundColor: Color?
    
    static let defaultPresets: [TextPreset] = [
        TextPreset(name: "Small", fontSize: 12, fontWeight: .regular, color: .black, backgroundColor: nil),
        TextPreset(name: "Medium", fontSize: 16, fontWeight: .regular, color: .black, backgroundColor: nil),
        TextPreset(name: "Large", fontSize: 20, fontWeight: .regular, color: .black, backgroundColor: nil),
        TextPreset(name: "Title", fontSize: 24, fontWeight: .bold, color: .black, backgroundColor: nil),
        TextPreset(name: "Highlight", fontSize: 16, fontWeight: .medium, color: .black, backgroundColor: .yellow),
        TextPreset(name: "Warning", fontSize: 16, fontWeight: .semibold, color: .red, backgroundColor: nil),
        TextPreset(name: "Note", fontSize: 14, fontWeight: .regular, color: .blue, backgroundColor: .white)
    ]
}

// MARK: - Font Weight Extension

extension Font.Weight {
    var nsWeight: NSFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}

// MARK: - Text Tool State Extension

extension TextTool {
    var currentText: String {
        textInput
    }
    
    var isEditing: Bool {
        isEditingText
    }
}
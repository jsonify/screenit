import Foundation
import SwiftUI

// MARK: - Text Tool

@MainActor
class TextTool: BaseAnnotationTool {
    
    private var isEditingText: Bool = false
    private var textInput: String = ""
    
    init() {
        super.init(type: .text)
    }
    
    // MARK: - Drawing Lifecycle
    
    override func handleDrawStart(_ point: CGPoint, state: AnnotationToolState) {
        startPoint = point
        currentPoint = point
        isDrawing = true
        
        // For text tool, we immediately show a text input
        beginTextEditing(at: point, state: state)
    }
    
    override func handleDrawUpdate(_ point: CGPoint, state: AnnotationToolState) {
        // Text tool doesn't need draw updates
    }
    
    override func handleDrawEnd(_ point: CGPoint, state: AnnotationToolState) -> Annotation? {
        defer {
            isDrawing = false
            isEditingText = false
            startPoint = nil
            currentPoint = nil
            textInput = ""
        }
        
        guard let start = startPoint,
              !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            return nil 
        }
        
        return createTextAnnotation(at: start, text: textInput, state: state)
    }
    
    // MARK: - Text Editing
    
    private func beginTextEditing(at point: CGPoint, state: AnnotationToolState) {
        isEditingText = true
        textInput = ""
        
        // In a real implementation, this would trigger a text input UI
        // For now, we'll use a placeholder text
        textInput = "Text Annotation"
    }
    
    func updateTextInput(_ text: String) {
        textInput = text
    }
    
    func finishTextEditing() -> Annotation? {
        guard let point = startPoint,
              !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            return nil 
        }
        
        return createTextAnnotation(at: point, text: textInput, state: AnnotationToolState())
    }
    
    // MARK: - Annotation Creation
    
    override func createAnnotation(from startPoint: CGPoint, to endPoint: CGPoint, state: AnnotationToolState) -> Annotation? {
        return createTextAnnotation(at: startPoint, text: textInput, state: state)
    }
    
    private func createTextAnnotation(at point: CGPoint, text: String, state: AnnotationToolState) -> Annotation? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        var properties = state.textProperties
        properties.text = text
        
        // Calculate text size (approximate)
        let textSize = calculateTextSize(text: text, fontSize: properties.fontSize, fontWeight: properties.fontWeight)
        let geometry = TextGeometry(position: point, size: textSize)
        
        return Annotation(
            type: .text,
            properties: properties,
            geometry: geometry
        )
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
        // This is a simplified text size calculation
        // In a real implementation, you'd use NSString.boundingRect or similar
        let characterWidth = fontSize * 0.6 // Approximate character width
        let lineHeight = fontSize * 1.2 // Approximate line height
        
        let lines = text.components(separatedBy: .newlines)
        let maxLineLength = lines.map { $0.count }.max() ?? 0
        
        return CGSize(
            width: Double(maxLineLength) * characterWidth,
            height: Double(lines.count) * lineHeight
        )
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
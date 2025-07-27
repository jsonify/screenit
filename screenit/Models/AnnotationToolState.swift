import Foundation
import SwiftUI

// MARK: - Annotation Tool State

@MainActor
class AnnotationToolState: ObservableObject {
    @Published var selectedTool: AnnotationType = .arrow
    @Published var color: Color = .black
    @Published var thickness: Double = 2.0
    @Published var fontSize: Double = 14.0
    @Published var fontWeight: Font.Weight = .regular
    @Published var arrowheadStyle: ArrowProperties.ArrowheadStyle = .standard
    @Published var fillOpacity: Double = 0.3
    @Published var blurRadius: Double = 10.0
    @Published var highlightOpacity: Double = 0.4
    
    // Predefined color palette
    let colorPalette: [Color] = [
        .black,
        .white,
        .red,
        .blue,
        .green,
        .yellow,
        .orange,
        .purple
    ]
    
    // Tool-specific property getters
    var arrowProperties: ArrowProperties {
        ArrowProperties(
            color: color,
            thickness: thickness,
            arrowheadStyle: arrowheadStyle
        )
    }
    
    var textProperties: TextProperties {
        TextProperties(
            color: color,
            fontSize: fontSize,
            text: "", // Will be set when text is entered
            backgroundColor: nil,
            fontWeight: fontWeight
        )
    }
    
    var rectangleProperties: RectangleProperties {
        RectangleProperties(
            color: color,
            thickness: thickness,
            fillColor: nil, // Can be set to color for filled rectangles
            fillOpacity: fillOpacity
        )
    }
    
    var highlightProperties: HighlightProperties {
        HighlightProperties(
            color: color,
            opacity: highlightOpacity
        )
    }
    
    var blurProperties: BlurProperties {
        BlurProperties(blurRadius: blurRadius)
    }
    
    init() {}
    
    // MARK: - State Management
    
    func selectTool(_ tool: AnnotationType) {
        selectedTool = tool
        
        // Set tool-specific defaults when switching tools
        switch tool {
        case .arrow:
            thickness = 2.0
            color = .black
        case .text:
            fontSize = 14.0
            fontWeight = .regular
            color = .black
        case .rectangle:
            thickness = 2.0
            fillOpacity = 0.3
            color = .black
        case .highlight:
            highlightOpacity = 0.4
            color = .yellow
        case .blur:
            blurRadius = 10.0
        }
    }
    
    func setColor(_ newColor: Color) {
        color = newColor
    }
    
    func setThickness(_ newThickness: Double) {
        thickness = max(1.0, min(10.0, newThickness))
    }
    
    func setFontSize(_ newSize: Double) {
        fontSize = max(8.0, min(72.0, newSize))
    }
    
    func setBlurRadius(_ newRadius: Double) {
        blurRadius = max(1.0, min(50.0, newRadius))
    }
    
    func setHighlightOpacity(_ newOpacity: Double) {
        highlightOpacity = max(0.1, min(1.0, newOpacity))
    }
    
    func setFillOpacity(_ newOpacity: Double) {
        fillOpacity = max(0.0, min(1.0, newOpacity))
    }
    
    func reset() {
        selectedTool = .arrow
        color = .black
        thickness = 2.0
        fontSize = 14.0
        fontWeight = .regular
        arrowheadStyle = .standard
        fillOpacity = 0.3
        blurRadius = 10.0
        highlightOpacity = 0.4
    }
}
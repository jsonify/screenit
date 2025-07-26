import Foundation
import SwiftUI

// MARK: - Highlight Tool

@MainActor
class HighlightTool: BaseAnnotationTool {
    
    init() {
        super.init(type: .highlight)
    }
    
    // MARK: - Annotation Creation
    
    override func createAnnotation(from startPoint: CGPoint, to endPoint: CGPoint, state: AnnotationToolState) -> Annotation? {
        // Don't create annotation for very small highlights
        let minSize: CGFloat = 5.0
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        
        guard width > minSize || height > minSize else { return nil }
        
        let properties = state.highlightProperties
        let geometry = HighlightGeometry(startPoint: startPoint, endPoint: endPoint)
        
        return Annotation(
            type: .highlight,
            properties: properties,
            geometry: geometry
        )
    }
    
    // MARK: - Rendering
    
    override func render(_ annotation: Annotation, in context: GraphicsContext) {
        guard let properties = annotation.properties as? HighlightProperties,
              let geometry = annotation.geometry as? HighlightGeometry else { return }
        
        let rect = geometry.rect
        let highlightPath = Path(rect)
        
        // Fill with highlight color and opacity
        context.fill(
            highlightPath,
            with: .color(properties.color.opacity(properties.opacity))
        )
        
        // Optional: Add subtle border for better visibility
        context.stroke(
            highlightPath,
            with: .color(properties.color.opacity(0.1)),
            style: StrokeStyle(lineWidth: 0.5)
        )
    }
    
    // MARK: - Hit Testing
    
    override func hitTest(_ point: CGPoint, annotation: Annotation) -> Bool {
        guard let geometry = annotation.geometry as? HighlightGeometry else { return false }
        
        // Expand bounds slightly for easier selection
        let expandedBounds = expandedBounds(geometry.bounds, by: 2.0)
        return expandedBounds.contains(point)
    }
    
    // MARK: - Configuration
    
    override func configure(with state: AnnotationToolState) {
        // Highlight tool can be configured with opacity and color
        // This method is called when tool state changes
    }
}
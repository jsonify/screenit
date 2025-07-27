import Foundation
import SwiftUI

// MARK: - Rectangle Tool

@MainActor
class RectangleTool: BaseAnnotationTool {
    
    init() {
        super.init(type: .rectangle)
    }
    
    // MARK: - Annotation Creation
    
    override func createAnnotation(from startPoint: CGPoint, to endPoint: CGPoint, state: AnnotationToolState) -> Annotation? {
        // Don't create annotation for very small rectangles
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        guard width > 5.0 && height > 5.0 else { return nil }
        
        let properties = state.rectangleProperties
        let geometry = RectangleGeometry(startPoint: startPoint, endPoint: endPoint)
        
        return Annotation(
            type: .rectangle,
            properties: properties,
            geometry: geometry
        )
    }
    
    // MARK: - Rendering
    
    override func render(_ annotation: Annotation, in context: GraphicsContext) {
        guard let properties = annotation.properties as? RectangleProperties,
              let geometry = annotation.geometry as? RectangleGeometry else { return }
        
        let rect = geometry.rect
        let path = Path(rect)
        
        // Draw fill if specified
        if let fillColor = properties.fillColor {
            context.fill(
                path,
                with: .color(fillColor.opacity(properties.fillOpacity))
            )
        }
        
        // Draw stroke
        context.stroke(
            path,
            with: .color(properties.color),
            style: StrokeStyle(
                lineWidth: properties.thickness,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
    
    // MARK: - Hit Testing
    
    override func hitTest(_ point: CGPoint, annotation: Annotation) -> Bool {
        guard let geometry = annotation.geometry as? RectangleGeometry,
              let properties = annotation.properties as? RectangleProperties else { return false }
        
        let rect = geometry.rect
        let strokeWidth = properties.thickness
        
        // Check if point is on the border (stroke)
        let outerRect = rect.insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2)
        let innerRect = rect.insetBy(dx: strokeWidth/2, dy: strokeWidth/2)
        
        // If there's a fill, check if point is inside the rectangle
        if properties.fillColor != nil {
            return outerRect.contains(point)
        } else {
            // Only check the border
            return outerRect.contains(point) && !innerRect.contains(point)
        }
    }
}
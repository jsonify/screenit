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

// MARK: - Highlight Tool

@MainActor
class HighlightTool: BaseAnnotationTool {
    
    init() {
        super.init(type: .highlight)
    }
    
    // MARK: - Annotation Creation
    
    override func createAnnotation(from startPoint: CGPoint, to endPoint: CGPoint, state: AnnotationToolState) -> Annotation? {
        // Don't create annotation for very small highlights
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        guard width > 5.0 && height > 5.0 else { return nil }
        
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
        let path = Path(rect)
        
        // Draw highlight with specified opacity
        context.fill(
            path,
            with: .color(properties.color.opacity(properties.opacity))
        )
    }
    
    // MARK: - Hit Testing
    
    override func hitTest(_ point: CGPoint, annotation: Annotation) -> Bool {
        guard let geometry = annotation.geometry as? HighlightGeometry else { return false }
        
        return geometry.rect.contains(point)
    }
}

// MARK: - Blur Tool

@MainActor
class BlurTool: BaseAnnotationTool {
    
    init() {
        super.init(type: .blur)
    }
    
    // MARK: - Annotation Creation
    
    override func createAnnotation(from startPoint: CGPoint, to endPoint: CGPoint, state: AnnotationToolState) -> Annotation? {
        // Don't create annotation for very small blur areas
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        guard width > 10.0 && height > 10.0 else { return nil }
        
        let properties = state.blurProperties
        let geometry = BlurGeometry(startPoint: startPoint, endPoint: endPoint)
        
        return Annotation(
            type: .blur,
            properties: properties,
            geometry: geometry
        )
    }
    
    // MARK: - Rendering
    
    override func render(_ annotation: Annotation, in context: GraphicsContext) {
        guard let properties = annotation.properties as? BlurProperties,
              let geometry = annotation.geometry as? BlurGeometry else { return }
        
        let rect = geometry.rect
        let path = Path(rect)
        
        // Create blur effect
        // Note: In a real implementation, this would apply a gaussian blur filter
        // to the underlying image content. For now, we'll draw a translucent overlay
        // to indicate the blur area.
        
        context.fill(
            path,
            with: .color(.gray.opacity(0.6))
        )
        
        // Draw border to indicate blur area
        context.stroke(
            path,
            with: .color(.gray),
            style: StrokeStyle(
                lineWidth: 1.0,
                lineCap: .round,
                lineJoin: .round,
                dash: [5, 5]
            )
        )
        
        // Add blur indicator icon in center (simplified)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let iconSize: CGFloat = min(20, min(rect.width, rect.height) * 0.3)
        
        if iconSize > 10 {
            let iconRect = CGRect(
                x: center.x - iconSize/2,
                y: center.y - iconSize/2,
                width: iconSize,
                height: iconSize
            )
            
            context.fill(
                Path(ellipseIn: iconRect),
                with: .color(.white.opacity(0.8))
            )
            
            context.stroke(
                Path(ellipseIn: iconRect),
                with: .color(.gray),
                style: StrokeStyle(lineWidth: 1.0)
            )
        }
    }
    
    // MARK: - Hit Testing
    
    override func hitTest(_ point: CGPoint, annotation: Annotation) -> Bool {
        guard let geometry = annotation.geometry as? BlurGeometry else { return false }
        
        return geometry.rect.contains(point)
    }
}
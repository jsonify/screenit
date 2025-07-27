import Foundation
import SwiftUI

// MARK: - Arrow Tool

@MainActor
class ArrowTool: BaseAnnotationTool {
    
    private var arrowheadSize: CGFloat = 12.0
    
    init() {
        super.init(type: .arrow)
    }
    
    // MARK: - Annotation Creation
    
    override func createAnnotation(from startPoint: CGPoint, to endPoint: CGPoint, state: AnnotationToolState) -> Annotation? {
        // Don't create annotation for very small arrows
        guard distance(from: startPoint, to: endPoint) > 5.0 else { return nil }
        
        let properties = state.arrowProperties
        let geometry = ArrowGeometry(startPoint: startPoint, endPoint: endPoint)
        
        return Annotation(
            type: .arrow,
            properties: properties,
            geometry: geometry
        )
    }
    
    // MARK: - Rendering
    
    override func render(_ annotation: Annotation, in context: GraphicsContext) {
        guard let properties = annotation.properties as? ArrowProperties,
              let geometry = annotation.geometry as? ArrowGeometry else { return }
        
        let startPoint = geometry.startPoint
        let endPoint = geometry.endPoint
        
        // Draw arrow line
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        context.stroke(
            path,
            with: .color(properties.color),
            style: StrokeStyle(
                lineWidth: properties.thickness,
                lineCap: .round,
                lineJoin: .round
            )
        )
        
        // Draw arrowhead
        drawArrowhead(
            at: endPoint,
            from: startPoint,
            properties: properties,
            in: context
        )
    }
    
    // MARK: - Hit Testing
    
    override func hitTest(_ point: CGPoint, annotation: Annotation) -> Bool {
        guard let geometry = annotation.geometry as? ArrowGeometry,
              let properties = annotation.properties as? ArrowProperties else { return false }
        
        let startPoint = geometry.startPoint
        let endPoint = geometry.endPoint
        let lineThickness = max(properties.thickness, 8.0) // Minimum hit area
        
        // Calculate distance from point to line segment
        let distanceToLine = distanceFromPointToLineSegment(
            point: point,
            lineStart: startPoint,
            lineEnd: endPoint
        )
        
        return distanceToLine <= lineThickness / 2.0
    }
    
    // MARK: - Private Methods
    
    private func drawArrowhead(at endPoint: CGPoint, from startPoint: CGPoint, properties: ArrowProperties, in context: GraphicsContext) {
        let angle = self.angle(from: startPoint, to: endPoint)
        let arrowAngle: Double = .pi / 6 // 30 degrees
        let headLength = arrowheadSize + properties.thickness * 2
        
        // Calculate arrowhead points
        let leftPoint = CGPoint(
            x: endPoint.x - headLength * cos(angle - arrowAngle),
            y: endPoint.y - headLength * sin(angle - arrowAngle)
        )
        
        let rightPoint = CGPoint(
            x: endPoint.x - headLength * cos(angle + arrowAngle),
            y: endPoint.y - headLength * sin(angle + arrowAngle)
        )
        
        // Create arrowhead path
        var arrowheadPath = Path()
        
        switch properties.arrowheadStyle {
        case .standard:
            arrowheadPath.move(to: leftPoint)
            arrowheadPath.addLine(to: endPoint)
            arrowheadPath.addLine(to: rightPoint)
            
        case .rounded:
            arrowheadPath.move(to: leftPoint)
            arrowheadPath.addQuadCurve(to: rightPoint, control: endPoint)
            arrowheadPath.addLine(to: endPoint)
            
        case .square:
            let backPoint = CGPoint(
                x: endPoint.x - headLength * 0.7 * cos(angle),
                y: endPoint.y - headLength * 0.7 * sin(angle)
            )
            
            arrowheadPath.move(to: leftPoint)
            arrowheadPath.addLine(to: endPoint)
            arrowheadPath.addLine(to: rightPoint)
            arrowheadPath.addLine(to: backPoint)
            arrowheadPath.closeSubpath()
        }
        
        // Stroke the arrowhead
        context.stroke(
            arrowheadPath,
            with: .color(properties.color),
            style: StrokeStyle(
                lineWidth: properties.thickness,
                lineCap: .round,
                lineJoin: .round
            )
        )
        
        // Fill arrowhead for square style
        if properties.arrowheadStyle == .square {
            context.fill(arrowheadPath, with: .color(properties.color))
        }
    }
    
    private func distanceFromPointToLineSegment(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let lineLength = distance(from: lineStart, to: lineEnd)
        
        if lineLength == 0 {
            return distance(from: point, to: lineStart)
        }
        
        let t = max(0, min(1, (
            (point.x - lineStart.x) * (lineEnd.x - lineStart.x) +
            (point.y - lineStart.y) * (lineEnd.y - lineStart.y)
        ) / (lineLength * lineLength)))
        
        let projection = CGPoint(
            x: lineStart.x + t * (lineEnd.x - lineStart.x),
            y: lineStart.y + t * (lineEnd.y - lineStart.y)
        )
        
        return distance(from: point, to: projection)
    }
    
    // MARK: - Tool Configuration
    
    override func configure(with state: AnnotationToolState) {
        // Update arrowhead size based on thickness for better visual consistency
        arrowheadSize = 12.0 + state.thickness * 2
    }
    
    override func activate() {
        super.activate()
        // Arrow tool specific activation logic if needed
    }
    
    override func deactivate() {
        super.deactivate()
        // Arrow tool specific deactivation logic if needed
    }
}
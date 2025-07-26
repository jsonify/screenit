import Foundation
import SwiftUI

// MARK: - Blur Tool

@MainActor
class BlurTool: BaseAnnotationTool {
    
    init() {
        super.init(type: .blur)
    }
    
    // MARK: - Annotation Creation
    
    override func createAnnotation(from startPoint: CGPoint, to endPoint: CGPoint, state: AnnotationToolState) -> Annotation? {
        // Don't create annotation for very small blur areas
        let minSize: CGFloat = 10.0
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        
        guard width > minSize || height > minSize else { return nil }
        
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
        let blurPath = Path(rect)
        
        // Draw a semi-transparent overlay to represent the blur effect
        // In a real implementation, this would apply actual blur to the underlying content
        context.fill(
            blurPath,
            with: .color(.gray.opacity(0.6))
        )
        
        // Add a dashed border to indicate blur area
        context.stroke(
            blurPath,
            with: .color(.gray),
            style: StrokeStyle(
                lineWidth: 1.5,
                dash: [4, 3],
                dashPhase: 0
            )
        )
        
        // Add blur radius indicator (small text or dots pattern)
        drawBlurIndicator(in: context, rect: rect, blurRadius: properties.blurRadius)
    }
    
    // MARK: - Hit Testing
    
    override func hitTest(_ point: CGPoint, annotation: Annotation) -> Bool {
        guard let geometry = annotation.geometry as? BlurGeometry else { return false }
        
        // Expand bounds slightly for easier selection
        let expandedBounds = expandedBounds(geometry.bounds, by: 3.0)
        return expandedBounds.contains(point)
    }
    
    // MARK: - Configuration
    
    override func configure(with state: AnnotationToolState) {
        // Blur tool can be configured with blur radius
        // This method is called when tool state changes
    }
    
    // MARK: - Private Methods
    
    private func drawBlurIndicator(in context: GraphicsContext, rect: CGRect, blurRadius: Double) {
        // Draw a pattern to indicate blur strength
        let centerX = rect.midX
        let centerY = rect.midY
        let maxRadius = min(rect.width, rect.height) / 4
        
        // Draw concentric circles to indicate blur
        for i in 1...3 {
            let radius = (maxRadius / 3) * CGFloat(i)
            let opacity = 0.3 - (0.1 * Double(i))
            
            let circlePath = Path { path in
                path.addEllipse(in: CGRect(
                    x: centerX - radius,
                    y: centerY - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
            }
            
            context.stroke(
                circlePath,
                with: .color(.white.opacity(opacity)),
                style: StrokeStyle(lineWidth: 1.0)
            )
        }
    }
}
import Foundation
import SwiftUI

// MARK: - Annotation Tool Protocol

@MainActor
protocol AnnotationTool {
    var type: AnnotationType { get }
    var isActive: Bool { get set }
    
    // Drawing lifecycle methods
    func handleDrawStart(_ point: CGPoint, state: AnnotationToolState) 
    func handleDrawUpdate(_ point: CGPoint, state: AnnotationToolState)
    func handleDrawEnd(_ point: CGPoint, state: AnnotationToolState) -> Annotation?
    
    // Rendering method for canvas
    func render(_ annotation: Annotation, in context: GraphicsContext)
    
    // Tool-specific configuration
    func configure(with state: AnnotationToolState)
    
    // Hit testing for selection
    func hitTest(_ point: CGPoint, annotation: Annotation) -> Bool
    
    // Tool activation/deactivation
    func activate()
    func deactivate()
}

// MARK: - Base Tool Implementation

@MainActor
class BaseAnnotationTool: AnnotationTool {
    let type: AnnotationType
    var isActive: Bool = false
    
    // Drawing state
    var startPoint: CGPoint?
    var currentPoint: CGPoint?
    var isDrawing: Bool = false
    
    init(type: AnnotationType) {
        self.type = type
    }
    
    // MARK: - Drawing Lifecycle (Default Implementations)
    
    func handleDrawStart(_ point: CGPoint, state: AnnotationToolState) {
        startPoint = point
        currentPoint = point
        isDrawing = true
    }
    
    func handleDrawUpdate(_ point: CGPoint, state: AnnotationToolState) {
        currentPoint = point
    }
    
    func handleDrawEnd(_ point: CGPoint, state: AnnotationToolState) -> Annotation? {
        defer {
            isDrawing = false
            startPoint = nil
            currentPoint = nil
        }
        
        guard let start = startPoint else { return nil }
        return createAnnotation(from: start, to: point, state: state)
    }
    
    // MARK: - Abstract Methods (To be overridden)
    
    func render(_ annotation: Annotation, in context: GraphicsContext) {
        // To be implemented by subclasses
        fatalError("render(_:in:) must be implemented by subclasses")
    }
    
    func configure(with state: AnnotationToolState) {
        // Default implementation - can be overridden
    }
    
    func hitTest(_ point: CGPoint, annotation: Annotation) -> Bool {
        // Default implementation checks bounds
        return annotation.geometry.bounds.contains(point)
    }
    
    func activate() {
        isActive = true
    }
    
    func deactivate() {
        isActive = false
        isDrawing = false
        startPoint = nil
        currentPoint = nil
    }
    
    // MARK: - Helper Methods
    
    func createAnnotation(from startPoint: CGPoint, to endPoint: CGPoint, state: AnnotationToolState) -> Annotation? {
        // To be implemented by subclasses
        fatalError("createAnnotation(from:to:state:) must be implemented by subclasses")
    }
    
    func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    func angle(from point1: CGPoint, to point2: CGPoint) -> Double {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return atan2(dy, dx)
    }
    
    func expandedBounds(_ rect: CGRect, by margin: CGFloat) -> CGRect {
        return rect.insetBy(dx: -margin, dy: -margin)
    }
}

// MARK: - Tool Factory

@MainActor
class AnnotationToolFactory {
    static func createTool(for type: AnnotationType) -> AnnotationTool {
        switch type {
        case .arrow:
            return ArrowTool()
        case .text:
            return TextTool()
        case .rectangle:
            return RectangleTool()
        case .highlight:
            return HighlightTool()
        case .blur:
            return BlurTool()
        }
    }
    
    static func createAllTools() -> [AnnotationType: AnnotationTool] {
        var tools: [AnnotationType: AnnotationTool] = [:]
        
        for type in AnnotationType.allCases {
            tools[type] = createTool(for: type)
        }
        
        return tools
    }
}
//
//  AnnotationCanvasView.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import SwiftUI

struct AnnotationCanvasView: View {
    @ObservedObject var annotationEngine: AnnotationEngine
    let imageSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Render all annotations
            for annotation in annotationEngine.annotations {
                renderAnnotation(annotation, in: context, canvasSize: size)
            }
        }
        .allowsHitTesting(false) // Let touch events pass through to gesture handlers
    }
    
    private func renderAnnotation(_ annotation: AnnotationData, in context: GraphicsContext, canvasSize: CGSize) {
        let color = Color(hex: annotation.color)
        
        switch annotation.type {
        case .arrow:
            renderArrow(annotation, color: color, in: context, canvasSize: canvasSize)
        case .text:
            renderText(annotation, color: color, in: context, canvasSize: canvasSize)
        case .rectangle:
            renderRectangle(annotation, color: color, in: context, canvasSize: canvasSize)
        case .highlight:
            renderHighlight(annotation, color: color, in: context, canvasSize: canvasSize)
        case .blur:
            renderBlur(annotation, in: context, canvasSize: canvasSize)
        }
    }
    
    private func renderArrow(_ annotation: AnnotationData, color: Color, in context: GraphicsContext, canvasSize: CGSize) {
        let startPoint = scalePoint(annotation.position, to: canvasSize)
        let endPoint = CGPoint(
            x: startPoint.x + scalePoint(CGPoint(x: annotation.size.width, y: 0), to: canvasSize).x,
            y: startPoint.y + scalePoint(CGPoint(x: 0, y: annotation.size.height), to: canvasSize).y
        )
        
        // Draw arrow line
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: CGFloat(annotation.thickness), lineCap: .round)
        )
        
        // Draw arrowhead
        let arrowHead = createArrowHead(from: startPoint, to: endPoint, size: CGFloat(annotation.thickness) * 3)
        context.fill(arrowHead, with: .color(color))
    }
    
    private func renderText(_ annotation: AnnotationData, color: Color, in context: GraphicsContext, canvasSize: CGSize) {
        let position = scalePoint(annotation.position, to: canvasSize)
        let fontSize = CGFloat(annotation.fontSize ?? 16)
        
        context.draw(
            Text(annotation.text ?? "")
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(color),
            at: position,
            anchor: .topLeading
        )
    }
    
    private func renderRectangle(_ annotation: AnnotationData, color: Color, in context: GraphicsContext, canvasSize: CGSize) {
        let startPoint = scalePoint(annotation.position, to: canvasSize)
        let size = CGSize(
            width: annotation.size.width * (canvasSize.width / imageSize.width),
            height: annotation.size.height * (canvasSize.height / imageSize.height)
        )
        
        let rect = CGRect(
            x: startPoint.x,
            y: startPoint.y,
            width: size.width,
            height: size.height
        )
        
        let path = Path(rect)
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: CGFloat(annotation.thickness))
        )
    }
    
    private func renderHighlight(_ annotation: AnnotationData, color: Color, in context: GraphicsContext, canvasSize: CGSize) {
        let startPoint = scalePoint(annotation.position, to: canvasSize)
        let size = CGSize(
            width: annotation.size.width * (canvasSize.width / imageSize.width),
            height: annotation.size.height * (canvasSize.height / imageSize.height)
        )
        
        let rect = CGRect(
            x: startPoint.x,
            y: startPoint.y,
            width: size.width,
            height: size.height
        )
        
        let path = Path(rect)
        context.fill(path, with: .color(color.opacity(0.3)))
    }
    
    private func renderBlur(_ annotation: AnnotationData, in context: GraphicsContext, canvasSize: CGSize) {
        let startPoint = scalePoint(annotation.position, to: canvasSize)
        let size = CGSize(
            width: annotation.size.width * (canvasSize.width / imageSize.width),
            height: annotation.size.height * (canvasSize.height / imageSize.height)
        )
        
        let rect = CGRect(
            x: startPoint.x,
            y: startPoint.y,
            width: size.width,
            height: size.height
        )
        
        // Create blur effect (simplified - show as semi-transparent gray for now)
        let path = Path(rect)
        context.fill(path, with: .color(.gray.opacity(0.6)))
        
        // Add border to indicate blur area
        context.stroke(
            path,
            with: .color(.gray),
            style: StrokeStyle(lineWidth: 2, dash: [5, 5])
        )
    }
    
    private func scalePoint(_ point: CGPoint, to canvasSize: CGSize) -> CGPoint {
        // Scale point from image coordinates to canvas coordinates
        let scaleX = canvasSize.width / imageSize.width
        let scaleY = canvasSize.height / imageSize.height
        
        return CGPoint(
            x: point.x * scaleX,
            y: point.y * scaleY
        )
    }
    
    private func createArrowHead(from start: CGPoint, to end: CGPoint, size: CGFloat) -> Path {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength = size
        let arrowAngle: CGFloat = .pi / 6 // 30 degrees
        
        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        
        var path = Path()
        path.move(to: end)
        path.addLine(to: arrowPoint1)
        path.addLine(to: arrowPoint2)
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    AnnotationCanvasView(
        annotationEngine: AnnotationEngine(),
        imageSize: CGSize(width: 800, height: 600)
    )
    .frame(width: 400, height: 300)
    .border(Color.gray)
}
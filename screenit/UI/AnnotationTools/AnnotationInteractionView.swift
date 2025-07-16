//
//  AnnotationInteractionView.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import SwiftUI
import Foundation

struct AnnotationInteractionView: View {
    @ObservedObject var annotationEngine: AnnotationEngine
    let imageSize: CGSize
    
    @State private var isDrawing = false
    @State private var currentStartPoint: CGPoint = .zero
    @State private var currentEndPoint: CGPoint = .zero
    @State private var showingTextInput = false
    @State private var textInputPosition: CGPoint = .zero
    @State private var textInputContent = ""
    
    var body: some View {
        ZStack {
            // Invisible interaction layer
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(annotationGesture)
            
            // Preview for current annotation being drawn
            if isDrawing && annotationEngine.currentTool.type != .text {
                Canvas { context, size in
                    renderPreview(in: context, canvasSize: size)
                }
                .allowsHitTesting(false)
            }
            
            // Text input overlay
            if showingTextInput {
                TextInputOverlay(
                    text: $textInputContent,
                    position: textInputPosition,
                    fontSize: CGFloat(annotationEngine.currentTool.fontSize),
                    onCommit: {
                        commitTextAnnotation()
                    },
                    onCancel: {
                        showingTextInput = false
                        textInputContent = ""
                    }
                )
            }
        }
    }
    
    private var annotationGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { value in
                handleDragEnded(value)
            }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        let location = scalePointToImage(value.location)
        
        if !isDrawing {
            // Start drawing
            isDrawing = true
            currentStartPoint = location
        }
        
        currentEndPoint = location
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let endLocation = scalePointToImage(value.location)
        
        switch annotationEngine.currentTool.type {
        case .text:
            handleTextPlacement(at: endLocation)
        case .arrow, .rectangle, .highlight, .blur:
            handleShapeCompletion(startPoint: currentStartPoint, endPoint: endLocation)
        }
        
        isDrawing = false
    }
    
    private func handleTextPlacement(at location: CGPoint) {
        textInputPosition = location
        textInputContent = ""
        showingTextInput = true
    }
    
    private func handleShapeCompletion(startPoint: CGPoint, endPoint: CGPoint) {
        // Only create annotation if there's meaningful distance
        let distance = sqrt(pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2))
        if distance < 10 { return } // Minimum distance threshold
        
        let size = CGSize(
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
        
        let annotation = AnnotationData(
            type: annotationEngine.currentTool.type,
            position: startPoint,
            size: size,
            color: annotationEngine.currentTool.color,
            thickness: annotationEngine.currentTool.thickness,
            text: nil,
            fontSize: annotationEngine.currentTool.fontSize
        )
        
        annotationEngine.addAnnotation(annotation)
    }
    
    private func commitTextAnnotation() {
        guard !textInputContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showingTextInput = false
            return
        }
        
        let annotation = AnnotationData(
            type: .text,
            position: textInputPosition,
            size: .zero,
            color: annotationEngine.currentTool.color,
            thickness: annotationEngine.currentTool.thickness,
            text: textInputContent,
            fontSize: annotationEngine.currentTool.fontSize
        )
        
        annotationEngine.addAnnotation(annotation)
        showingTextInput = false
        textInputContent = ""
    }
    
    private func renderPreview(in context: GraphicsContext, canvasSize: CGSize) {
        let color = annotationEngine.currentTool.color
        let startPoint = scalePointToCanvas(currentStartPoint, canvasSize: canvasSize)
        let endPoint = scalePointToCanvas(currentEndPoint, canvasSize: canvasSize)
        
        switch annotationEngine.currentTool.type {
        case .arrow:
            renderArrowPreview(from: startPoint, to: endPoint, color: color, in: context)
        case .rectangle:
            renderRectanglePreview(from: startPoint, to: endPoint, color: color, in: context)
        case .highlight:
            renderHighlightPreview(from: startPoint, to: endPoint, color: color, in: context)
        case .blur:
            renderBlurPreview(from: startPoint, to: endPoint, in: context)
        case .text:
            break // Text is handled separately
        }
    }
    
    private func renderArrowPreview(from start: CGPoint, to end: CGPoint, color: Color, in context: GraphicsContext) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        
        context.stroke(
            path,
            with: .color(color.opacity(0.7)),
            style: StrokeStyle(lineWidth: CGFloat(annotationEngine.currentTool.thickness), lineCap: .round)
        )
        
        // Arrow head preview
        let arrowHead = createArrowHead(from: start, to: end, size: CGFloat(annotationEngine.currentTool.thickness) * 3)
        context.fill(arrowHead, with: .color(color.opacity(0.7)))
    }
    
    private func renderRectanglePreview(from start: CGPoint, to end: CGPoint, color: Color, in context: GraphicsContext) {
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        let path = Path(rect)
        context.stroke(
            path,
            with: .color(color.opacity(0.7)),
            style: StrokeStyle(lineWidth: CGFloat(annotationEngine.currentTool.thickness))
        )
    }
    
    private func renderHighlightPreview(from start: CGPoint, to end: CGPoint, color: Color, in context: GraphicsContext) {
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        let path = Path(rect)
        context.fill(path, with: .color(color.opacity(0.2)))
    }
    
    private func renderBlurPreview(from start: CGPoint, to end: CGPoint, in context: GraphicsContext) {
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        let path = Path(rect)
        context.fill(path, with: .color(.gray.opacity(0.4)))
        context.stroke(
            path,
            with: .color(.gray.opacity(0.7)),
            style: StrokeStyle(lineWidth: 2, dash: [5, 5])
        )
    }
    
    private func scalePointToImage(_ point: CGPoint) -> CGPoint {
        // This should match the coordinate system used by the annotation engine
        return point
    }
    
    private func scalePointToCanvas(_ point: CGPoint, canvasSize: CGSize) -> CGPoint {
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

struct TextInputOverlay: View {
    @Binding var text: String
    let position: CGPoint
    let fontSize: CGFloat
    let onCommit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack {
            TextField("Enter text", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: fontSize))
                .onSubmit {
                    onCommit()
                }
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    onCommit()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .position(x: position.x + 100, y: position.y - 30) // Offset to avoid overlap
    }
}

#Preview {
    AnnotationInteractionView(
        annotationEngine: AnnotationEngine(),
        imageSize: CGSize(width: 800, height: 600)
    )
    .frame(width: 400, height: 300)
    .border(Color.gray)
}
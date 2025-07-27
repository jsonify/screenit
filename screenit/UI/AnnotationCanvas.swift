import SwiftUI

// MARK: - Annotation Canvas

struct AnnotationCanvas: View {
    // MARK: - Properties
    
    let annotations: [Annotation]
    let imageSize: CGSize
    @ObservedObject var engine: AnnotationEngine
    
    @State private var currentDrawing: CurrentDrawing?
    @State private var canvasSize: CGSize = .zero
    
    // MARK: - Computed Properties
    
    var isDrawing: Bool {
        currentDrawing != nil
    }
    
    private var scaleFactor: CGFloat {
        guard canvasSize.width > 0 && canvasSize.height > 0 else { return 1.0 }
        
        let scaleX = canvasSize.width / imageSize.width
        let scaleY = canvasSize.height / imageSize.height
        return min(scaleX, scaleY)
    }
    
    private var drawingOffset: CGSize {
        let scaledImageSize = CGSize(
            width: imageSize.width * scaleFactor,
            height: imageSize.height * scaleFactor
        )
        
        return CGSize(
            width: (canvasSize.width - scaledImageSize.width) / 2,
            height: (canvasSize.height - scaledImageSize.height) / 2
        )
    }
    
    // MARK: - Initialization
    
    init(annotations: [Annotation], engine: AnnotationEngine, imageSize: CGSize) {
        self.annotations = annotations
        self.engine = engine
        self.imageSize = imageSize
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Canvas { context, size in
                // Update canvas size
                DispatchQueue.main.async {
                    if canvasSize != size {
                        canvasSize = size
                    }
                }
                
                // Draw existing annotations
                drawAnnotations(context: context, size: size)
                
                // Draw current drawing in progress
                if let drawing = currentDrawing {
                    drawCurrentAnnotation(context: context, drawing: drawing, size: size)
                }
            }
            .background(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value)
                    }
                    .onEnded { value in
                        handleDragEnded(value)
                    }
            )
            .onTapGesture { location in
                handleTap(at: location)
            }
            
            // Text input overlay
            if let textTool = engine.selectedTool as? TextTool,
               textTool.textInputState.isEditing {
                TextInputView(
                    text: Binding(
                        get: { textTool.textInputState.text },
                        set: { textTool.updateTextInput($0) }
                    ),
                    isEditing: Binding(
                        get: { textTool.textInputState.isEditing },
                        set: { _ in }
                    ),
                    position: transformToCanvasCoordinates(
                        textTool.textInputState.position,
                        size: canvasSize
                    ),
                    fontSize: textTool.textInputState.configuration.fontSize * scaleFactor,
                    fontWeight: textTool.textInputState.configuration.fontWeight,
                    color: textTool.textInputState.configuration.color,
                    backgroundColor: textTool.textInputState.configuration.backgroundColor,
                    onComplete: { text in
                        if let annotation = textTool.finishTextEditing() {
                            engine.addAnnotation(annotation)
                        }
                    },
                    onCancel: {
                        textTool.cancelTextEditing()
                    }
                )
            }
        }
    }
    
    // MARK: - Drawing Methods
    
    private func drawAnnotations(context: GraphicsContext, size: CGSize) {
        for annotation in annotations {
            drawAnnotation(context: context, annotation: annotation, size: size)
        }
    }
    
    private func drawAnnotation(context: GraphicsContext, annotation: Annotation, size: CGSize) {
        switch annotation.type {
        case .arrow:
            drawArrow(context: context, annotation: annotation, size: size)
        case .text:
            drawText(context: context, annotation: annotation, size: size)
        case .rectangle:
            drawRectangle(context: context, annotation: annotation, size: size)
        case .highlight:
            drawHighlight(context: context, annotation: annotation, size: size)
        case .blur:
            drawBlur(context: context, annotation: annotation, size: size)
        }
    }
    
    private func drawArrow(context: GraphicsContext, annotation: Annotation, size: CGSize) {
        guard let geometry = annotation.geometry as? ArrowGeometry,
              let properties = annotation.properties as? ArrowProperties else { return }
        
        // Create a transformed annotation with canvas coordinates
        let transformedGeometry = ArrowGeometry(
            startPoint: transformToCanvasCoordinates(geometry.startPoint, size: size),
            endPoint: transformToCanvasCoordinates(geometry.endPoint, size: size)
        )
        
        // Scale thickness for canvas
        let scaledProperties = ArrowProperties(
            color: properties.color,
            thickness: properties.thickness * scaleFactor,
            arrowheadStyle: properties.arrowheadStyle
        )
        
        let transformedAnnotation = Annotation(
            type: .arrow,
            properties: scaledProperties,
            geometry: transformedGeometry
        )
        
        // Use ArrowTool's render method for consistent rendering
        if let arrowTool = engine.getTool(for: .arrow) as? ArrowTool {
            arrowTool.render(transformedAnnotation, in: context)
        } else {
            // Fallback basic rendering
            drawBasicArrow(context: context, from: transformedGeometry.startPoint, to: transformedGeometry.endPoint, properties: scaledProperties)
        }
    }
    
    private func drawBasicArrow(context: GraphicsContext, from startPoint: CGPoint, to endPoint: CGPoint, properties: ArrowProperties) {
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
        
        // Draw basic arrowhead
        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle - arrowAngle),
            y: endPoint.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle + arrowAngle),
            y: endPoint.y - arrowLength * sin(angle + arrowAngle)
        )
        
        var arrowPath = Path()
        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: arrowPoint1)
        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: arrowPoint2)
        
        context.stroke(
            arrowPath,
            with: .color(properties.color),
            style: StrokeStyle(
                lineWidth: properties.thickness,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
    
    private func drawText(context: GraphicsContext, annotation: Annotation, size: CGSize) {
        guard let geometry = annotation.geometry as? TextGeometry,
              let properties = annotation.properties as? TextProperties else { return }
        
        let position = transformToCanvasCoordinates(geometry.position, size: size)
        let fontSize = properties.fontSize * scaleFactor
        
        // Draw background if specified
        if let backgroundColor = properties.backgroundColor {
            let backgroundRect = CGRect(
                origin: position,
                size: CGSize(
                    width: geometry.size.width * scaleFactor,
                    height: geometry.size.height * scaleFactor
                )
            )
            context.fill(Path(backgroundRect), with: .color(backgroundColor))
        }
        
        // Draw text
        let resolvedText = context.resolve(Text(properties.text)
            .foregroundColor(properties.color)
            .font(.system(size: fontSize, weight: properties.fontWeight))
        )
        
        context.draw(resolvedText, at: position, anchor: .topLeading)
    }
    
    private func drawRectangle(context: GraphicsContext, annotation: Annotation, size: CGSize) {
        guard let geometry = annotation.geometry as? RectangleGeometry,
              let properties = annotation.properties as? RectangleProperties else { return }
        
        let rect = transformRectToCanvasCoordinates(geometry.rect, size: size)
        let rectanglePath = Path(rect)
        
        // Draw fill if specified
        if let fillColor = properties.fillColor {
            context.fill(
                rectanglePath,
                with: .color(fillColor.opacity(properties.fillOpacity))
            )
        }
        
        // Draw stroke
        context.stroke(
            rectanglePath,
            with: .color(properties.color),
            lineWidth: properties.thickness * scaleFactor
        )
    }
    
    private func drawHighlight(context: GraphicsContext, annotation: Annotation, size: CGSize) {
        guard let geometry = annotation.geometry as? HighlightGeometry,
              let properties = annotation.properties as? HighlightProperties else { return }
        
        let rect = transformRectToCanvasCoordinates(geometry.rect, size: size)
        let highlightPath = Path(rect)
        
        context.fill(
            highlightPath,
            with: .color(properties.color.opacity(properties.opacity))
        )
    }
    
    private func drawBlur(context: GraphicsContext, annotation: Annotation, size: CGSize) {
        guard let geometry = annotation.geometry as? BlurGeometry,
              let properties = annotation.properties as? BlurProperties else { return }
        
        let rect = transformRectToCanvasCoordinates(geometry.rect, size: size)
        let blurPath = Path(rect)
        
        // Draw a semi-transparent overlay to represent blur effect
        context.fill(
            blurPath,
            with: .color(.gray.opacity(0.6))
        )
        
        // Add visual indication of blur
        let strokePath = Path(rect)
        context.stroke(
            strokePath,
            with: .color(.gray),
            style: StrokeStyle(lineWidth: 1, dash: [5, 5])
        )
    }
    
    private func drawCurrentAnnotation(context: GraphicsContext, drawing: CurrentDrawing, size: CGSize) {
        guard let tool = engine.selectedTool else { return }
        
        let startPoint = transformToCanvasCoordinates(drawing.startPoint, size: size)
        let currentPoint = transformToCanvasCoordinates(drawing.currentPoint, size: size)
        
        switch tool.type {
        case .arrow:
            drawPreviewArrow(context: context, from: startPoint, to: currentPoint)
        case .rectangle:
            drawPreviewRectangle(context: context, from: startPoint, to: currentPoint)
        case .highlight:
            drawPreviewHighlight(context: context, from: startPoint, to: currentPoint)
        case .blur:
            drawPreviewBlur(context: context, from: startPoint, to: currentPoint)
        case .text:
            drawPreviewText(context: context, at: startPoint)
        }
    }
    
    private func drawPreviewArrow(context: GraphicsContext, from startPoint: CGPoint, to endPoint: CGPoint) {
        let color = engine.toolState.color.opacity(0.7)
        let thickness = engine.toolState.thickness * scaleFactor
        
        // Draw arrow line
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(
                lineWidth: thickness,
                lineCap: .round,
                lineJoin: .round
            )
        )
        
        // Draw preview arrowhead
        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowLength: CGFloat = 15 * scaleFactor
        let arrowAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle - arrowAngle),
            y: endPoint.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle + arrowAngle),
            y: endPoint.y - arrowLength * sin(angle + arrowAngle)
        )
        
        var arrowPath = Path()
        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: arrowPoint1)
        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: arrowPoint2)
        
        context.stroke(
            arrowPath,
            with: .color(color),
            style: StrokeStyle(
                lineWidth: thickness,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
    
    private func drawPreviewRectangle(context: GraphicsContext, from startPoint: CGPoint, to endPoint: CGPoint) {
        let rect = CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
        
        let rectanglePath = Path(rect)
        context.stroke(
            rectanglePath,
            with: .color(engine.toolState.color.opacity(0.7)),
            lineWidth: engine.toolState.thickness * scaleFactor
        )
    }
    
    private func drawPreviewHighlight(context: GraphicsContext, from startPoint: CGPoint, to endPoint: CGPoint) {
        let rect = CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
        
        let highlightPath = Path(rect)
        context.fill(
            highlightPath,
            with: .color(engine.toolState.color.opacity(0.3))
        )
    }
    
    private func drawPreviewBlur(context: GraphicsContext, from startPoint: CGPoint, to endPoint: CGPoint) {
        let rect = CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
        
        let blurPath = Path(rect)
        context.fill(
            blurPath,
            with: .color(.gray.opacity(0.4))
        )
    }
    
    private func drawPreviewText(context: GraphicsContext, at position: CGPoint) {
        // Draw a small cursor indicator for text tool
        var path = Path()
        path.move(to: position)
        path.addLine(to: CGPoint(x: position.x, y: position.y + 20))
        
        context.stroke(
            path,
            with: .color(engine.toolState.color),
            lineWidth: 2
        )
    }
    
    // MARK: - Coordinate Transformation
    
    func transformToCanvasCoordinates(_ point: CGPoint, size: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x * scaleFactor + drawingOffset.width,
            y: point.y * scaleFactor + drawingOffset.height
        )
    }
    
    func transformToImageCoordinates(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: (point.x - drawingOffset.width) / scaleFactor,
            y: (point.y - drawingOffset.height) / scaleFactor
        )
    }
    
    private func transformRectToCanvasCoordinates(_ rect: CGRect, size: CGSize) -> CGRect {
        let origin = transformToCanvasCoordinates(rect.origin, size: size)
        return CGRect(
            x: origin.x,
            y: origin.y,
            width: rect.width * scaleFactor,
            height: rect.height * scaleFactor
        )
    }
    
    func isPointInBounds(_ point: CGPoint) -> Bool {
        let imagePoint = transformToImageCoordinates(point)
        return imagePoint.x >= 0 && imagePoint.x <= imageSize.width &&
               imagePoint.y >= 0 && imagePoint.y <= imageSize.height
    }
    
    // MARK: - Gesture Handling
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        let location = value.location
        
        if currentDrawing == nil {
            handleDrawStart(at: location)
        } else {
            handleDrawUpdate(at: location)
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        handleDrawEnd(at: value.location)
    }
    
    private func handleTap(at location: CGPoint) {
        if engine.selectedTool?.type == .text {
            // For text tool, we start text editing at the tap location
            let imagePoint = transformToImageCoordinates(location)
            engine.handleCanvasEvent(.drawStart(imagePoint))
        }
    }
    
    
    // MARK: - Drawing Event Handling
    
    func handleDrawStart(at point: CGPoint) {
        guard engine.selectedTool != nil, isPointInBounds(point) else { return }
        
        let imagePoint = transformToImageCoordinates(point)
        currentDrawing = CurrentDrawing(startPoint: imagePoint, currentPoint: imagePoint)
        
        // Notify engine
        engine.handleCanvasEvent(.drawStart(imagePoint))
    }
    
    func handleDrawUpdate(at point: CGPoint) {
        guard var drawing = currentDrawing else { return }
        
        let imagePoint = transformToImageCoordinates(point)
        drawing.currentPoint = imagePoint
        currentDrawing = drawing
        
        // Notify engine
        engine.handleCanvasEvent(.drawUpdate(imagePoint))
    }
    
    func handleDrawEnd(at point: CGPoint) {
        guard currentDrawing != nil else { return }
        
        let imagePoint = transformToImageCoordinates(point)
        
        // Notify engine
        engine.handleCanvasEvent(.drawEnd(imagePoint))
        
        // Clear current drawing
        currentDrawing = nil
    }
    
    func cancelCurrentDrawing() {
        currentDrawing = nil
    }
}

// MARK: - Current Drawing State

struct CurrentDrawing {
    let startPoint: CGPoint
    var currentPoint: CGPoint
}

// MARK: - Preview

#if DEBUG
struct AnnotationCanvas_Previews: PreviewProvider {
    static var previews: some View {
        let engine = AnnotationEngine()
        
        // Add sample annotations
        let arrowAnnotation = Annotation(
            type: .arrow,
            properties: ArrowProperties(color: .red, thickness: 3.0),
            geometry: ArrowGeometry(startPoint: CGPoint(x: 50, y: 50), endPoint: CGPoint(x: 150, y: 100))
        )
        
        let rectAnnotation = Annotation(
            type: .rectangle,
            properties: RectangleProperties(color: .blue, thickness: 2.0),
            geometry: RectangleGeometry(rect: CGRect(x: 200, y: 150, width: 100, height: 80))
        )
        
        engine.addAnnotation(arrowAnnotation)
        engine.addAnnotation(rectAnnotation)
        
        return AnnotationCanvas(
            annotations: engine.annotations,
            engine: engine,
            imageSize: CGSize(width: 800, height: 600)
        )
        .frame(width: 400, height: 300)
        .border(Color.gray)
    }
}
#endif
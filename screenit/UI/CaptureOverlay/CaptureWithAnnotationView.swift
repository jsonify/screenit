import SwiftUI
import AppKit

/// Enhanced capture view that integrates annotation capabilities
struct CaptureWithAnnotationView: View {
    
    // MARK: - State
    
    @State private var capturePhase: CapturePhase = .selecting
    @State private var selectionRect: CGRect = .zero
    @State private var capturedImage: NSImage?
    @State private var isSelecting: Bool = false
    @State private var startPoint: CGPoint = .zero
    @State private var currentPoint: CGPoint = .zero
    @State private var showCrosshair: Bool = true
    @State private var showMagnifier: Bool = true
    
    // Annotation state
    @StateObject private var annotationEngine = AnnotationEngine()
    @State private var isAnnotationMode: Bool = false
    
    // Callbacks
    private var onCaptureComplete: ((NSImage, [Annotation]) -> Void)?
    private var onCancelCapture: (() -> Void)?
    private var onCursorMoved: ((CGPoint) -> Void)?
    
    // MARK: - Computed Properties
    
    private var imageSize: CGSize {
        guard let image = capturedImage else { return .zero }
        return image.size
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch capturePhase {
                case .selecting:
                    selectionView(geometry: geometry)
                case .annotating:
                    annotationView(geometry: geometry)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onKeyPress(.escape) {
            handleEscapeKey()
            return .handled
        }
        .onKeyPress(.return) {
            handleReturnKey()
            return .handled
        }
    }
    
    // MARK: - Selection View
    
    @ViewBuilder
    private func selectionView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Dimmed background
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Selection area (clear rectangle)
            if isSelecting || !selectionRect.isEmpty {
                SelectionRectangleView(rect: selectionRect)
            }
            
            // Crosshair cursor
            if showCrosshair && !isSelecting {
                CrosshairView(position: currentPoint)
            }
            
            // Instructions
            if !isSelecting && selectionRect.isEmpty {
                InstructionsView()
            }
            
            // Selection dimensions display
            if isSelecting && !selectionRect.isEmpty {
                SelectionDimensionsView(rect: selectionRect)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    handleSelectionDragChanged(value, in: geometry)
                }
                .onEnded { value in
                    handleSelectionDragEnded(value, in: geometry)
                }
        )
        .onHover { isHovering in
            showCrosshair = isHovering
            showMagnifier = isHovering && !isSelecting
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                currentPoint = location
                onCursorMoved?(location)
            case .ended:
                showMagnifier = false
            }
        }
        .onAppear {
            setupInitialState(geometry)
        }
    }
    
    // MARK: - Annotation View
    
    @ViewBuilder
    private func annotationView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Display the captured image
            if let image = capturedImage {
                imageView(image: image, geometry: geometry)
            }
            
            // Annotation canvas overlay
            if let image = capturedImage {
                AnnotationCanvas(
                    annotations: annotationEngine.annotations,
                    engine: annotationEngine,
                    imageSize: image.size
                )
                .frame(
                    width: selectionRect.width,
                    height: selectionRect.height
                )
                .position(
                    x: selectionRect.midX,
                    y: selectionRect.midY
                )
            }
            
            // Annotation toolbar
            if isAnnotationMode {
                annotationToolbar()
            }
            
            // Instructions for annotation mode
            if isAnnotationMode {
                annotationInstructionsView()
            }
        }
    }
    
    @ViewBuilder
    private func imageView(image: NSImage, geometry: GeometryProxy) -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(
                width: selectionRect.width,
                height: selectionRect.height
            )
            .position(
                x: selectionRect.midX,
                y: selectionRect.midY
            )
            .background(Color.white)
            .clipShape(Rectangle())
    }
    
    @ViewBuilder
    private func annotationToolbar() -> some View {
        HStack(spacing: 12) {
            // Tool selection buttons
            ForEach(AnnotationType.allCases, id: \.self) { toolType in
                Button(action: {
                    annotationEngine.selectTool(toolType)
                }) {
                    Image(systemName: toolType.iconName)
                        .foregroundColor(annotationEngine.toolState.selectedTool == toolType ? .blue : .white)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(annotationEngine.toolState.selectedTool == toolType ? Color.white.opacity(0.2) : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.5))
            
            // Undo/Redo buttons
            Button(action: {
                annotationEngine.undo()
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundColor(annotationEngine.canUndo ? .white : .gray)
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(!annotationEngine.canUndo)
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                annotationEngine.redo()
            }) {
                Image(systemName: "arrow.uturn.forward")
                    .foregroundColor(annotationEngine.canRedo ? .white : .gray)
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(!annotationEngine.canRedo)
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.5))
            
            // Complete button
            Button(action: {
                completeCapture()
            }) {
                Text("Done")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.8))
        )
        .position(
            x: selectionRect.midX,
            y: selectionRect.maxY + 40
        )
    }
    
    @ViewBuilder
    private func annotationInstructionsView() -> some View {
        VStack(spacing: 6) {
            Text("Select a tool and draw on the image")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Text("Press ESC to cancel • Enter to finish")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
        )
        .position(
            x: selectionRect.midX,
            y: selectionRect.minY - 30
        )
    }
    
    // MARK: - Selection Gesture Handlers
    
    private func handleSelectionDragChanged(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        if !isSelecting {
            isSelecting = true
            startPoint = value.startLocation
            showCrosshair = false
            showMagnifier = false
        }
        
        currentPoint = value.location
        updateSelectionRect()
        onCursorMoved?(value.location)
    }
    
    private func handleSelectionDragEnded(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        guard isSelecting else { return }
        
        updateSelectionRect()
        
        // Check if selection is valid
        if selectionRect.width > 10 && selectionRect.height > 10 {
            // Capture the selected area and switch to annotation mode
            captureSelectedArea()
        } else {
            // Invalid selection - reset
            resetSelection()
            showCrosshair = true
        }
    }
    
    private func updateSelectionRect() {
        let minX = min(startPoint.x, currentPoint.x)
        let minY = min(startPoint.y, currentPoint.y)
        let maxX = max(startPoint.x, currentPoint.x)
        let maxY = max(startPoint.y, currentPoint.y)
        
        selectionRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    private func setupInitialState(_ geometry: GeometryProxy) {
        currentPoint = CGPoint(
            x: geometry.size.width / 2,
            y: geometry.size.height / 2
        )
    }
    
    // MARK: - Capture Logic
    
    private func captureSelectedArea() {
        // This would normally use ScreenCaptureKit to capture the selected area
        // For now, we'll create a placeholder image
        let image = createPlaceholderImage(size: selectionRect.size)
        
        capturedImage = image
        capturePhase = .annotating
        isAnnotationMode = true
        
        // Initialize annotation engine for this capture
        annotationEngine.startAnnotationSession(for: selectionRect.size)
    }
    
    private func createPlaceholderImage(size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Draw a gradient background as placeholder
        let gradient = NSGradient(starting: .systemBlue, ending: .systemPurple)
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
        
        image.unlockFocus()
        return image
    }
    
    private func completeCapture() {
        guard let image = capturedImage else { return }
        
        let annotations = annotationEngine.endAnnotationSession()
        onCaptureComplete?(image, annotations)
    }
    
    // MARK: - Keyboard Handlers
    
    private func handleEscapeKey() {
        switch capturePhase {
        case .selecting:
            onCancelCapture?()
        case .annotating:
            // Return to selection or cancel
            if selectionRect.isEmpty {
                onCancelCapture?()
            } else {
                capturePhase = .selecting
                capturedImage = nil
                isAnnotationMode = false
                annotationEngine.cancelAnnotationSession()
                resetSelection()
            }
        }
    }
    
    private func handleReturnKey() {
        switch capturePhase {
        case .selecting:
            // If we have a valid selection, capture it
            if !selectionRect.isEmpty && selectionRect.width > 10 && selectionRect.height > 10 {
                captureSelectedArea()
            }
        case .annotating:
            // Complete the capture
            completeCapture()
        }
    }
    
    // MARK: - State Management
    
    private func resetSelection() {
        selectionRect = .zero
        isSelecting = false
        showCrosshair = true
        startPoint = .zero
        currentPoint = .zero
    }
    
    // MARK: - Public Interface
    
    func onCaptureComplete(_ callback: @escaping (NSImage, [Annotation]) -> Void) -> CaptureWithAnnotationView {
        var copy = self
        copy.onCaptureComplete = callback
        return copy
    }
    
    func onCancel(_ callback: @escaping () -> Void) -> CaptureWithAnnotationView {
        var copy = self
        copy.onCancelCapture = callback
        return copy
    }
    
    func onCursorMove(_ callback: @escaping (CGPoint) -> Void) -> CaptureWithAnnotationView {
        var copy = self
        copy.onCursorMoved = callback
        return copy
    }
}

// MARK: - Capture Phase Enum

enum CapturePhase {
    case selecting
    case annotating
}

// MARK: - Annotation Type Extensions

extension AnnotationType {
    var iconName: String {
        switch self {
        case .arrow:
            return "arrow.up.right"
        case .text:
            return "text.cursor"
        case .rectangle:
            return "rectangle"
        case .highlight:
            return "highlighter"
        case .blur:
            return "eye.slash"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CaptureWithAnnotationView_Previews: PreviewProvider {
    static var previews: some View {
        CaptureWithAnnotationView()
            .frame(width: 800, height: 600)
            .background(Color.blue.opacity(0.3))
    }
}
#endif
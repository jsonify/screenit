import SwiftUI
import AppKit

/// SwiftUI view for the capture overlay with crosshair cursor and selection rectangle
struct CaptureOverlayView: View {
    
    @State private var selectionRect: CGRect = .zero
    @State private var isSelecting: Bool = false
    @State private var startPoint: CGPoint = .zero
    @State private var currentPoint: CGPoint = .zero
    @State private var showCrosshair: Bool = true
    @State private var showMagnifier: Bool = true
    
    // Callbacks
    private var onSelectionComplete: ((CGRect) -> Void)?
    private var onCancelSelection: (() -> Void)?
    private var onCursorMoved: ((CGPoint) -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
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
            .contentShape(Rectangle()) // Make entire area clickable
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        handleDragChanged(value, in: geometry)
                    }
                    .onEnded { value in
                        handleDragEnded(value, in: geometry)
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
                    // Notify parent about cursor movement for magnifier
                    onCursorMoved?(location)
                case .ended:
                    showMagnifier = false
                }
            }
            .onAppear {
                setupInitialState(geometry)
            }
        }
        .ignoresSafeArea(.all)
    }
    
    // MARK: - Gesture Handlers
    
    private func handleDragChanged(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        if !isSelecting {
            // Start new selection
            isSelecting = true
            startPoint = value.startLocation
            showCrosshair = false
            showMagnifier = false // Hide magnifier during selection
        }
        
        currentPoint = value.location
        updateSelectionRect()
        
        // Notify about cursor movement during selection
        onCursorMoved?(value.location)
    }
    
    private func handleDragEnded(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        guard isSelecting else { return }
        
        updateSelectionRect()
        
        // Check if selection is valid (minimum size)
        if selectionRect.width > 10 && selectionRect.height > 10 {
            // Valid selection - complete capture
            onSelectionComplete?(selectionRect)
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
        // Center the initial cursor position
        currentPoint = CGPoint(
            x: geometry.size.width / 2,
            y: geometry.size.height / 2
        )
    }
    
    // MARK: - Public Interface
    
    func resetSelection() {
        selectionRect = .zero
        isSelecting = false
        showCrosshair = true
        startPoint = .zero
        currentPoint = .zero
    }
    
    // MARK: - View Modifiers
    
    func onSelection(_ callback: @escaping (CGRect) -> Void) -> CaptureOverlayView {
        var copy = self
        copy.onSelectionComplete = callback
        return copy
    }
    
    func onCancel(_ callback: @escaping () -> Void) -> CaptureOverlayView {
        var copy = self
        copy.onCancelSelection = callback
        return copy
    }
    
    func onCursorMove(_ callback: @escaping (CGPoint) -> Void) -> CaptureOverlayView {
        var copy = self
        copy.onCursorMoved = callback
        return copy
    }
}

// MARK: - Crosshair View

struct CrosshairView: View {
    let position: CGPoint
    
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(height: 1)
                .shadow(color: .black, radius: 1, x: 0, y: 0)
            
            // Vertical line
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 1)
                .shadow(color: .black, radius: 1, x: 0, y: 0)
        }
        .position(position)
        .allowsHitTesting(false)
    }
}

// MARK: - Selection Rectangle View

struct SelectionRectangleView: View {
    let rect: CGRect
    
    var body: some View {
        ZStack {
            // Clear area (punch hole in dimmed background)
            Rectangle()
                .fill(Color.clear)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .blendMode(.destinationOut)
            
            // Selection border
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .shadow(color: .black, radius: 1, x: 0, y: 0)
            
            // Corner handles
            SelectionHandlesView(rect: rect)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Selection Handles View

struct SelectionHandlesView: View {
    let rect: CGRect
    private let handleSize: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Top-left handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .stroke(Color.black, lineWidth: 1)
                .frame(width: handleSize, height: handleSize)
                .position(x: rect.minX, y: rect.minY)
            
            // Top-right handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .stroke(Color.black, lineWidth: 1)
                .frame(width: handleSize, height: handleSize)
                .position(x: rect.maxX, y: rect.minY)
            
            // Bottom-left handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .stroke(Color.black, lineWidth: 1)
                .frame(width: handleSize, height: handleSize)
                .position(x: rect.minX, y: rect.maxY)
            
            // Bottom-right handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .stroke(Color.black, lineWidth: 1)
                .frame(width: handleSize, height: handleSize)
                .position(x: rect.maxX, y: rect.maxY)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Selection Dimensions View

struct SelectionDimensionsView: View {
    let rect: CGRect
    
    private var dimensionText: String {
        "\(Int(rect.width)) × \(Int(rect.height))"
    }
    
    var body: some View {
        Text(dimensionText)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .position(
                x: rect.midX,
                y: rect.minY - 20 // Position above selection
            )
            .allowsHitTesting(false)
    }
}

// MARK: - Instructions View

struct InstructionsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Click and drag to select an area")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text("Press ESC to cancel")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
        .position(x: 400, y: 100) // Approximate center position
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    CaptureOverlayView()
        .frame(width: 800, height: 600)
        .background(Color.blue.opacity(0.3)) // Simulate desktop background
}
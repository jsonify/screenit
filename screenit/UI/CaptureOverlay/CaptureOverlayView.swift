//
//  CaptureOverlayView.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import SwiftUI

struct CaptureOverlayView: View {
    @ObservedObject var captureEngine: CaptureEngine
    @ObservedObject var annotationEngine: AnnotationEngine
    @State private var selectionRect: CGRect = .zero
    @State private var isDragging = false
    @State private var startPoint: CGPoint = .zero
    @State private var currentPoint: CGPoint = .zero
    @State private var showMagnifier = false
    @State private var magnifierPosition: CGPoint = .zero
    
    let onCaptureComplete: (NSImage?) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            if isDragging || !selectionRect.isEmpty {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .fill(Color.clear)
                    .frame(width: selectionRect.width, height: selectionRect.height)
                    .position(x: selectionRect.midX, y: selectionRect.midY)
            }
            
            if showMagnifier {
                MagnifierView(position: magnifierPosition)
                    .position(magnifierPosition)
            }
        }
        .onAppear {
            setupCursor()
        }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        startPoint = value.startLocation
                    }
                    
                    currentPoint = value.location
                    updateSelectionRect()
                    updateMagnifier(at: value.location)
                }
                .onEnded { _ in
                    isDragging = false
                    showMagnifier = false
                    captureSelection()
                }
        )
        .onHover { isHovering in
            if isHovering && !isDragging {
                showMagnifier = true
            } else if !isDragging {
                showMagnifier = false
            }
        }
        .onKeyPress(.escape) {
            onCancel()
            return .handled
        }
        .onKeyPress(.return) {
            captureSelection()
            return .handled
        }
        .onKeyPress(.space) {
            captureSelection()
            return .handled
        }
    }
    
    private func setupCursor() {
        NSCursor.crosshair.set()
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
    
    private func updateMagnifier(at position: CGPoint) {
        magnifierPosition = position
        showMagnifier = true
    }
    
    private func captureSelection() {
        guard !selectionRect.isEmpty else {
            onCancel()
            return
        }
        
        Task {
            let image = await captureEngine.captureArea(selectionRect)
            await MainActor.run {
                onCaptureComplete(image)
            }
        }
    }
}

struct MagnifierView: View {
    let position: CGPoint
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .stroke(Color.gray, lineWidth: 1)
                .frame(width: 120, height: 120)
                .overlay(
                    Text("Magnifier")
                        .font(.caption)
                        .foregroundColor(.gray)
                )
            
            VStack(spacing: 2) {
                Text("RGB: 255, 128, 64")
                    .font(.system(size: 10, family: .monospaced))
                Text("(\(Int(position.x)), \(Int(position.y)))")
                    .font(.system(size: 10, family: .monospaced))
            }
            .padding(4)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
        }
    }
}
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
    @State private var mousePosition: CGPoint = .zero
    @State private var showMagnifier = false
    @State private var magnifierPosition: CGPoint = .zero
    @State private var magnifierImage: NSImage?
    @State private var currentRGB: (red: Int, green: Int, blue: Int) = (0, 0, 0)
    
    let onCaptureComplete: (NSImage?) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            if isDragging || !selectionRect.isEmpty {
                GeometryReader { geometry in
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        Rectangle()
                            .frame(width: selectionRect.width, height: selectionRect.height)
                            .position(x: selectionRect.midX, y: selectionRect.midY)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                    
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                        .fill(Color.clear)
                        .frame(width: selectionRect.width, height: selectionRect.height)
                        .position(x: selectionRect.midX, y: selectionRect.midY)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .overlay(
                            Rectangle()
                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                .frame(width: selectionRect.width, height: selectionRect.height)
                                .position(x: selectionRect.midX, y: selectionRect.midY)
                        )
                    
                    if selectionRect.width > 60 && selectionRect.height > 30 {
                        VStack(spacing: 2) {
                            Text("\(Int(selectionRect.width)) × \(Int(selectionRect.height))")
                                .font(.system(size: 12, design: .monospaced))
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .position(
                            x: selectionRect.midX,
                            y: selectionRect.minY - 20
                        )
                    }
                }
            } else {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            }
            
            if showMagnifier {
                MagnifierView(
                    position: mousePosition,
                    magnifierImage: magnifierImage,
                    rgbValues: currentRGB
                )
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
                    mousePosition = value.location
                    updateSelectionRect()
                    updateMagnifier(at: value.location)
                }
                .onEnded { _ in
                    isDragging = false
                    showMagnifier = false
                    captureSelection()
                }
        )
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                if !isDragging {
                    mousePosition = location
                    updateMagnifier(at: location)
                    showMagnifier = true
                }
            case .ended:
                if !isDragging {
                    showMagnifier = false
                }
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
        let screenBounds = NSScreen.main?.frame ?? CGRect.zero
        let magnifierSize: CGFloat = 140
        let offset: CGFloat = 20
        
        var newPosition = position
        newPosition.x += offset
        newPosition.y -= offset
        
        if newPosition.x + magnifierSize > screenBounds.maxX {
            newPosition.x = position.x - magnifierSize - offset
        }
        if newPosition.y - magnifierSize < screenBounds.minY {
            newPosition.y = position.y + magnifierSize + offset
        }
        
        magnifierPosition = newPosition
        showMagnifier = true
        
        Task {
            if let image = await captureEngine.samplePixelsAt(point: position, size: CGSize(width: 21, height: 21)) {
                await MainActor.run {
                    self.magnifierImage = image
                }
            }
            
            if let rgb = await captureEngine.getRGBAt(point: position) {
                await MainActor.run {
                    self.currentRGB = rgb
                }
            }
        }
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
    let magnifierImage: NSImage?
    let rgbValues: (red: Int, green: Int, blue: Int)
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                if let image = magnifierImage {
                    Image(nsImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 110, height: 110)
                        .clipped()
                        .cornerRadius(6)
                        .overlay(
                            ZStack {
                                Rectangle()
                                    .stroke(Color.red, lineWidth: 1)
                                    .frame(width: 5, height: 5)
                                
                                Rectangle()
                                    .fill(Color.red.opacity(0.3))
                                    .frame(width: 5, height: 5)
                            }
                        )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                }
            }
            
            VStack(spacing: 2) {
                Text("RGB: \(rgbValues.red), \(rgbValues.green), \(rgbValues.blue)")
                    .font(.system(size: 10, design: .monospaced))
                Text("(\(Int(position.x)), \(Int(position.y)))")
                    .font(.system(size: 10, design: .monospaced))
            }
            .padding(6)
            .background(Color.black.opacity(0.9))
            .foregroundColor(.white)
            .cornerRadius(6)
        }
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}
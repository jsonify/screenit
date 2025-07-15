//
//  AnnotationToolbar.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import SwiftUI

struct AnnotationToolbar: View {
    @ObservedObject var annotationEngine: AnnotationEngine
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple]
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(AnnotationType.allCases, id: \.self) { type in
                    Button(action: { annotationEngine.selectTool(type) }) {
                        Image(systemName: iconForTool(type))
                            .font(.system(size: 16))
                            .foregroundColor(annotationEngine.currentTool.type == type ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32, height: 32)
                    .background(
                        annotationEngine.currentTool.type == type ? 
                        Color.blue : Color.gray.opacity(0.2)
                    )
                    .cornerRadius(6)
                }
            }
            
            Divider()
                .frame(height: 24)
            
            HStack(spacing: 6) {
                ForEach(colors, id: \.self) { color in
                    Button(action: { annotationEngine.setToolColor(color) }) {
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .opacity(colorMatches(color) ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
                .frame(height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Thickness")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { annotationEngine.currentTool.thickness },
                        set: { annotationEngine.setToolThickness($0) }
                    ),
                    in: 1...10,
                    step: 1
                )
                .frame(width: 80)
            }
            
            if annotationEngine.currentTool.type == .text {
                Divider()
                    .frame(height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Font Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: Binding(
                            get: { annotationEngine.currentTool.fontSize },
                            set: { annotationEngine.setToolFontSize($0) }
                        ),
                        in: 8...48,
                        step: 2
                    )
                    .frame(width: 80)
                }
            }
            
            Divider()
                .frame(height: 24)
            
            HStack(spacing: 8) {
                Button(action: { annotationEngine.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16))
                }
                .disabled(!annotationEngine.canUndo())
                .buttonStyle(.plain)
                
                Button(action: { annotationEngine.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 16))
                }
                .disabled(!annotationEngine.canRedo())
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func iconForTool(_ type: AnnotationType) -> String {
        switch type {
        case .arrow:
            return "arrow.up.right"
        case .text:
            return "textformat"
        case .rectangle:
            return "rectangle"
        case .highlight:
            return "highlighter"
        case .blur:
            return "aqi.medium"
        }
    }
    
    private func colorMatches(_ color: Color) -> Bool {
        return color.toHex() == annotationEngine.currentTool.color.toHex()
    }
}
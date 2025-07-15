//
//  AnnotationEngine.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import Foundation
import SwiftUI
import AppKit

enum AnnotationType: String, CaseIterable, Codable {
    case arrow = "arrow"
    case text = "text"
    case rectangle = "rectangle"
    case highlight = "highlight"
    case blur = "blur"
}

struct AnnotationTool {
    var type: AnnotationType
    var color: Color = .red
    var thickness: CGFloat = 2.0
    var fontSize: CGFloat = 16.0
    var text: String = ""
}

@MainActor
class AnnotationEngine: ObservableObject {
    @Published var currentTool: AnnotationTool = AnnotationTool(type: .arrow)
    @Published var annotations: [AnnotationData] = []
    @Published var isAnnotating = false
    
    private var undoStack: [AnnotationData] = []
    private var redoStack: [AnnotationData] = []
    
    func selectTool(_ type: AnnotationType) {
        currentTool.type = type
    }
    
    func setToolColor(_ color: Color) {
        currentTool.color = color
    }
    
    func setToolThickness(_ thickness: CGFloat) {
        currentTool.thickness = thickness
    }
    
    func setToolFontSize(_ fontSize: CGFloat) {
        currentTool.fontSize = fontSize
    }
    
    func addAnnotation(_ annotation: AnnotationData) {
        annotations.append(annotation)
        undoStack.append(annotation)
        redoStack.removeAll()
    }
    
    func undo() {
        guard let lastAnnotation = undoStack.popLast() else { return }
        
        if let index = annotations.firstIndex(where: { $0.id == lastAnnotation.id }) {
            annotations.remove(at: index)
            redoStack.append(lastAnnotation)
        }
    }
    
    func redo() {
        guard let lastUndone = redoStack.popLast() else { return }
        
        annotations.append(lastUndone)
        undoStack.append(lastUndone)
    }
    
    func clearAnnotations() {
        annotations.removeAll()
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    func canUndo() -> Bool {
        return !undoStack.isEmpty
    }
    
    func canRedo() -> Bool {
        return !redoStack.isEmpty
    }
}

struct AnnotationData: Identifiable, Codable {
    let id: UUID
    let type: AnnotationType
    let position: CGPoint
    let size: CGSize
    let color: String
    let thickness: CGFloat
    let text: String?
    let fontSize: CGFloat?
    
    init(type: AnnotationType, position: CGPoint, size: CGSize = .zero, color: Color, thickness: CGFloat = 2.0, text: String? = nil, fontSize: CGFloat? = nil) {
        self.id = UUID()
        self.type = type
        self.position = position
        self.size = size
        self.color = color.toHex()
        self.thickness = thickness
        self.text = text
        self.fontSize = fontSize
    }
}


extension Color {
    func toHex() -> String {
        let components = NSColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = components[0]
        let g = components[1]
        let b = components[2]
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
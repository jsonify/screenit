import Foundation
import SwiftUI

// MARK: - Annotation Types

enum AnnotationType: String, CaseIterable, Codable {
    case arrow
    case text
    case rectangle
    case highlight
    case blur
}

// MARK: - Core Annotation Model

struct Annotation: Identifiable {
    let id: UUID
    let type: AnnotationType
    let properties: AnnotationProperties
    let geometry: AnnotationGeometry
    let timestamp: Date
    
    init(id: UUID = UUID(), type: AnnotationType, properties: AnnotationProperties, geometry: AnnotationGeometry, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.properties = properties
        self.geometry = geometry
        self.timestamp = timestamp
    }
}

// MARK: - Equatable Implementation for Annotation

extension Annotation: Equatable {
    static func == (lhs: Annotation, rhs: Annotation) -> Bool {
        return lhs.id == rhs.id &&
               lhs.type == rhs.type &&
               lhs.timestamp == rhs.timestamp
    }
}

// MARK: - Annotation Properties

protocol AnnotationProperties {
    var color: Color { get set }
    var thickness: Double { get set }
}

// MARK: - Equatable implementations for properties

extension ArrowProperties: Equatable {
    static func == (lhs: ArrowProperties, rhs: ArrowProperties) -> Bool {
        return lhs.thickness == rhs.thickness && 
               lhs.arrowheadStyle == rhs.arrowheadStyle
    }
}

extension TextProperties: Equatable {
    static func == (lhs: TextProperties, rhs: TextProperties) -> Bool {
        return lhs.fontSize == rhs.fontSize &&
               lhs.text == rhs.text &&
               lhs.fontWeight == rhs.fontWeight
    }
}

extension RectangleProperties: Equatable {
    static func == (lhs: RectangleProperties, rhs: RectangleProperties) -> Bool {
        return lhs.thickness == rhs.thickness &&
               lhs.fillOpacity == rhs.fillOpacity
    }
}

extension HighlightProperties: Equatable {
    static func == (lhs: HighlightProperties, rhs: HighlightProperties) -> Bool {
        return lhs.opacity == rhs.opacity
    }
}

extension BlurProperties: Equatable {
    static func == (lhs: BlurProperties, rhs: BlurProperties) -> Bool {
        return lhs.blurRadius == rhs.blurRadius
    }
}

struct ArrowProperties: AnnotationProperties {
    var color: Color
    var thickness: Double
    var arrowheadStyle: ArrowheadStyle
    
    enum ArrowheadStyle: String, CaseIterable, Codable {
        case standard
        case rounded
        case square
    }
    
    init(color: Color = .black, thickness: Double = 2.0, arrowheadStyle: ArrowheadStyle = .standard) {
        self.color = color
        self.thickness = thickness
        self.arrowheadStyle = arrowheadStyle
    }
}

struct TextProperties: AnnotationProperties {
    var color: Color
    var thickness: Double // Not used for text, but required by protocol
    var fontSize: Double
    var text: String
    var backgroundColor: Color?
    var fontWeight: Font.Weight
    
    init(color: Color = .black, fontSize: Double = 14.0, text: String = "", backgroundColor: Color? = nil, fontWeight: Font.Weight = .regular) {
        self.color = color
        self.thickness = 1.0 // Default value for protocol compliance
        self.fontSize = fontSize
        self.text = text
        self.backgroundColor = backgroundColor
        self.fontWeight = fontWeight
    }
}

struct RectangleProperties: AnnotationProperties {
    var color: Color
    var thickness: Double
    var fillColor: Color?
    var fillOpacity: Double
    
    init(color: Color = .black, thickness: Double = 2.0, fillColor: Color? = nil, fillOpacity: Double = 0.3) {
        self.color = color
        self.thickness = thickness
        self.fillColor = fillColor
        self.fillOpacity = fillOpacity
    }
}

struct HighlightProperties: AnnotationProperties {
    var color: Color
    var thickness: Double // Not used for highlight, but required by protocol
    var opacity: Double
    
    init(color: Color = .yellow, opacity: Double = 0.4) {
        self.color = color
        self.thickness = 1.0 // Default value for protocol compliance
        self.opacity = opacity
    }
}

struct BlurProperties: AnnotationProperties {
    var color: Color // Not used for blur, but required by protocol
    var thickness: Double // Not used for blur, but required by protocol
    var blurRadius: Double
    
    init(blurRadius: Double = 10.0) {
        self.color = .clear // Default value for protocol compliance
        self.thickness = 1.0 // Default value for protocol compliance
        self.blurRadius = blurRadius
    }
}

// MARK: - Annotation Geometry

protocol AnnotationGeometry {
    var bounds: CGRect { get }
}

struct ArrowGeometry: AnnotationGeometry {
    let startPoint: CGPoint
    let endPoint: CGPoint
    
    var bounds: CGRect {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let maxX = max(startPoint.x, endPoint.x)
        let maxY = max(startPoint.y, endPoint.y)
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    init(startPoint: CGPoint, endPoint: CGPoint) {
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
}

struct TextGeometry: AnnotationGeometry {
    let position: CGPoint
    let size: CGSize
    
    var bounds: CGRect {
        CGRect(origin: position, size: size)
    }
    
    init(position: CGPoint, size: CGSize) {
        self.position = position
        self.size = size
    }
}

struct RectangleGeometry: AnnotationGeometry {
    let rect: CGRect
    
    var bounds: CGRect {
        rect
    }
    
    init(rect: CGRect) {
        self.rect = rect
    }
    
    init(startPoint: CGPoint, endPoint: CGPoint) {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        
        self.rect = CGRect(x: minX, y: minY, width: width, height: height)
    }
}

struct HighlightGeometry: AnnotationGeometry {
    let rect: CGRect
    
    var bounds: CGRect {
        rect
    }
    
    init(rect: CGRect) {
        self.rect = rect
    }
    
    init(startPoint: CGPoint, endPoint: CGPoint) {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        
        self.rect = CGRect(x: minX, y: minY, width: width, height: height)
    }
}

struct BlurGeometry: AnnotationGeometry {
    let rect: CGRect
    
    var bounds: CGRect {
        rect
    }
    
    init(rect: CGRect) {
        self.rect = rect
    }
    
    init(startPoint: CGPoint, endPoint: CGPoint) {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        
        self.rect = CGRect(x: minX, y: minY, width: width, height: height)
    }
}

// MARK: - Canvas Events

enum CanvasEvent {
    case drawStart(CGPoint)
    case drawUpdate(CGPoint)
    case drawEnd(CGPoint)
}

// MARK: - Extensions for Future Codable Support
// Color and Font.Weight Codable extensions can be added later when persistence is needed
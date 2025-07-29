import Foundation
import CoreData
import SwiftUI
import OSLog

/// Core Data managed object representing annotation data
@objc(AnnotationData)
public class AnnotationData: NSManagedObject {
    
    private let logger = Logger(subsystem: "com.screenit.app", category: "AnnotationData")
    
    // MARK: - Configuration
    
    /// Configures this AnnotationData from a domain Annotation object
    /// - Parameters:
    ///   - annotation: Source annotation
    ///   - captureItem: Associated capture item
    func configure(from annotation: Annotation, for captureItem: CaptureItem) {
        self.id = annotation.id
        self.type = annotation.type.rawValue
        self.timestamp = annotation.timestamp
        self.captureItem = captureItem
        
        // Convert absolute coordinates to normalized coordinates (0.0-1.0)
        let imageSize = CGSize(width: CGFloat(captureItem.width), height: CGFloat(captureItem.height))
        let bounds = annotation.geometry.bounds
        
        self.normalizedX = Float(bounds.origin.x / imageSize.width)
        self.normalizedY = Float(bounds.origin.y / imageSize.height)
        self.normalizedWidth = Float(bounds.size.width / imageSize.width)
        self.normalizedHeight = Float(bounds.size.height / imageSize.height)
        
        // Store common properties
        self.colorHex = annotation.properties.color.toHex()
        self.thickness = annotation.properties.thickness
        
        // Store type-specific properties as JSON
        self.properties = encodeProperties(from: annotation)
    }
    
    /// Converts this AnnotationData back to a domain Annotation object
    /// - Parameter imageSize: Size of the associated image for coordinate conversion
    /// - Returns: Domain Annotation object or nil if conversion fails
    func toDomainObject(imageSize: CGSize) -> Annotation? {
        guard let id = id,
              let typeString = type,
              let annotationType = AnnotationType(rawValue: typeString),
              let timestamp = timestamp else {
            logger.error("Missing required fields for annotation conversion")
            return nil
        }
        
        // Convert normalized coordinates back to absolute coordinates
        let absoluteBounds = CGRect(
            x: CGFloat(normalizedX) * imageSize.width,
            y: CGFloat(normalizedY) * imageSize.height,
            width: CGFloat(normalizedWidth) * imageSize.width,
            height: CGFloat(normalizedHeight) * imageSize.height
        )
        
        // Create geometry based on type
        let geometry: AnnotationGeometry
        switch annotationType {
        case .arrow:
            let startPoint = absoluteBounds.origin
            let endPoint = CGPoint(
                x: absoluteBounds.origin.x + absoluteBounds.size.width,
                y: absoluteBounds.origin.y + absoluteBounds.size.height
            )
            geometry = ArrowGeometry(startPoint: startPoint, endPoint: endPoint)
            
        case .text:
            geometry = TextGeometry(position: absoluteBounds.origin, size: absoluteBounds.size)
            
        case .rectangle, .highlight, .blur:
            geometry = createRectangleGeometry(for: annotationType, bounds: absoluteBounds)
        }
        
        // Create properties based on type
        let annotationProperties = createProperties(for: annotationType)
        
        return Annotation(
            id: id,
            type: annotationType,
            properties: annotationProperties,
            geometry: geometry,
            timestamp: timestamp
        )
    }
    
    // MARK: - Private Helpers
    
    private func encodeProperties(from annotation: Annotation) -> Data? {
        var propertyDict: [String: Any] = [:]
        
        switch annotation.type {
        case .arrow:
            if let arrowProps = annotation.properties as? ArrowProperties {
                propertyDict["arrowheadStyle"] = arrowProps.arrowheadStyle.rawValue
            }
            
        case .text:
            if let textProps = annotation.properties as? TextProperties {
                propertyDict["text"] = textProps.text
                propertyDict["fontSize"] = textProps.fontSize
                propertyDict["fontWeight"] = textProps.fontWeight.value
                if let bgColor = textProps.backgroundColor {
                    propertyDict["backgroundColor"] = bgColor.toHex()
                }
            }
            
        case .rectangle:
            if let rectProps = annotation.properties as? RectangleProperties {
                propertyDict["fillOpacity"] = rectProps.fillOpacity
                if let fillColor = rectProps.fillColor {
                    propertyDict["fillColor"] = fillColor.toHex()
                }
            }
            
        case .highlight:
            if let highlightProps = annotation.properties as? HighlightProperties {
                propertyDict["opacity"] = highlightProps.opacity
            }
            
        case .blur:
            if let blurProps = annotation.properties as? BlurProperties {
                propertyDict["blurRadius"] = blurProps.blurRadius
            }
        }
        
        do {
            return try JSONSerialization.data(withJSONObject: propertyDict)
        } catch {
            logger.error("Failed to encode annotation properties: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func createProperties(for type: AnnotationType) -> AnnotationProperties {
        let color = Color(hex: colorHex ?? "#000000") ?? .black
        
        switch type {
        case .arrow:
            var arrowProps = ArrowProperties(color: color, thickness: thickness)
            if let propertiesData = properties,
               let dict = try? JSONSerialization.jsonObject(with: propertiesData) as? [String: Any],
               let styleString = dict["arrowheadStyle"] as? String,
               let style = ArrowProperties.ArrowheadStyle(rawValue: styleString) {
                arrowProps.arrowheadStyle = style
            }
            return arrowProps
            
        case .text:
            var textProps = TextProperties(color: color)
            if let propertiesData = properties,
               let dict = try? JSONSerialization.jsonObject(with: propertiesData) as? [String: Any] {
                textProps.text = dict["text"] as? String ?? ""
                textProps.fontSize = dict["fontSize"] as? Double ?? 14.0
                if let fontWeightValue = dict["fontWeight"] as? Int {
                    textProps.fontWeight = Font.Weight(fontWeightValue)
                }
                if let bgColorHex = dict["backgroundColor"] as? String {
                    textProps.backgroundColor = Color(hex: bgColorHex)
                }
            }
            return textProps
            
        case .rectangle:
            var rectProps = RectangleProperties(color: color, thickness: thickness)
            if let propertiesData = properties,
               let dict = try? JSONSerialization.jsonObject(with: propertiesData) as? [String: Any] {
                rectProps.fillOpacity = dict["fillOpacity"] as? Double ?? 0.3
                if let fillColorHex = dict["fillColor"] as? String {
                    rectProps.fillColor = Color(hex: fillColorHex)
                }
            }
            return rectProps
            
        case .highlight:
            var highlightProps = HighlightProperties(color: color)
            if let propertiesData = properties,
               let dict = try? JSONSerialization.jsonObject(with: propertiesData) as? [String: Any] {
                highlightProps.opacity = dict["opacity"] as? Double ?? 0.4
            }
            return highlightProps
            
        case .blur:
            var blurProps = BlurProperties()
            if let propertiesData = properties,
               let dict = try? JSONSerialization.jsonObject(with: propertiesData) as? [String: Any] {
                blurProps.blurRadius = dict["blurRadius"] as? Double ?? 10.0
            }
            return blurProps
        }
    }
    
    private func createRectangleGeometry(for type: AnnotationType, bounds: CGRect) -> AnnotationGeometry {
        switch type {
        case .rectangle:
            return RectangleGeometry(rect: bounds)
        case .highlight:
            return HighlightGeometry(rect: bounds)
        case .blur:
            return BlurGeometry(rect: bounds)
        default:
            return RectangleGeometry(rect: bounds)
        }
    }
}

// MARK: - Color Extensions

private extension Color {
    /// Converts Color to hex string
    func toHex() -> String {
        let uiColor = NSColor(self)
        guard let rgbColor = uiColor.usingColorSpace(.sRGB) else { return "#000000" }
        
        let red = Int(rgbColor.redComponent * 255)
        let green = Int(rgbColor.greenComponent * 255)
        let blue = Int(rgbColor.blueComponent * 255)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

// MARK: - Font.Weight Extensions

private extension Font.Weight {
    init(_ value: Int) {
        switch value {
        case 100: self = .ultraLight
        case 200: self = .thin
        case 300: self = .light
        case 400: self = .regular
        case 500: self = .medium
        case 600: self = .semibold
        case 700: self = .bold
        case 800: self = .heavy
        case 900: self = .black
        default: self = .regular
        }
    }
    
    var value: Int {
        switch self {
        case .ultraLight: return 100
        case .thin: return 200
        case .light: return 300
        case .regular: return 400
        case .medium: return 500
        case .semibold: return 600
        case .bold: return 700
        case .heavy: return 800
        case .black: return 900
        default: return 400
        }
    }
}
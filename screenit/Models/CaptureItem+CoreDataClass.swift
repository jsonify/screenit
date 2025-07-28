import Foundation
import CoreData
import AppKit
import OSLog

/// Core Data managed object representing a screenshot capture
@objc(CaptureItem)
public class CaptureItem: NSManagedObject {
    
    private let logger = Logger(subsystem: "com.screenit.app", category: "CaptureItem")
    
    // MARK: - Convenience Initializers
    
    /// Creates a new CaptureItem with the provided image and metadata
    /// - Parameters:
    ///   - context: The managed object context
    ///   - image: The captured image
    ///   - annotations: Optional array of annotations
    /// - Returns: Configured CaptureItem instance
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        with image: NSImage,
        annotations: [Annotation] = []
    ) -> CaptureItem {
        let captureItem = CaptureItem(context: context)
        captureItem.id = UUID()
        captureItem.timestamp = Date()
        captureItem.width = Int32(image.size.width)
        captureItem.height = Int32(image.size.height)
        
        // Convert image to PNG data
        if let imageData = image.pngData {
            captureItem.imageData = imageData
            captureItem.fileSize = Int64(imageData.count)
        }
        
        // Generate thumbnail
        captureItem.generateThumbnail(from: image)
        
        // Add annotations if provided
        for annotation in annotations {
            captureItem.addAnnotation(annotation, in: context)
        }
        
        return captureItem
    }
    
    // MARK: - Image Handling
    
    /// Returns the full-size image from stored data
    var image: NSImage? {
        guard let imageData = imageData else { return nil }
        return NSImage(data: imageData)
    }
    
    /// Returns the thumbnail image from stored data
    var thumbnailImage: NSImage? {
        guard let thumbnailData = thumbnailData else { return nil }
        return NSImage(data: thumbnailData)
    }
    
    /// Generates and stores thumbnail data from the provided image
    /// - Parameter image: Source image to create thumbnail from
    private func generateThumbnail(from image: NSImage) {
        let thumbnailSize = CGSize(width: 200, height: 200)
        let thumbnail = image.resized(to: thumbnailSize)
        
        if let thumbnailPNGData = thumbnail.pngData {
            self.thumbnailData = thumbnailPNGData
        }
    }
    
    // MARK: - Annotation Management
    
    /// Adds an annotation to this capture item
    /// - Parameters:
    ///   - annotation: The annotation to add
    ///   - context: The managed object context
    func addAnnotation(_ annotation: Annotation, in context: NSManagedObjectContext) {
        let annotationData = AnnotationData(context: context)
        annotationData.configure(from: annotation, for: self)
        addToAnnotations(annotationData)
    }
    
    /// Returns all annotations as domain objects
    var domainAnnotations: [Annotation] {
        guard let annotations = annotations else { return [] }
        
        return annotations.compactMap { annotationData in
            guard let annotation = annotationData as? AnnotationData else { return nil }
            return annotation.toDomainObject(imageSize: CGSize(width: CGFloat(width), height: CGFloat(height)))
        }
    }
    
    // MARK: - Metadata
    
    /// Returns formatted file size string
    var formattedFileSize: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    /// Returns formatted dimensions string
    var formattedDimensions: String {
        return "\(width) × \(height)"
    }
    
    /// Returns formatted timestamp string
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp ?? Date())
    }
}

// MARK: - NSImage Extensions

private extension NSImage {
    
    /// Converts the image to PNG data
    var pngData: Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(using: .png, properties: [:])
    }
    
    /// Resizes the image to the specified size while maintaining aspect ratio
    /// - Parameter size: Target size
    /// - Returns: Resized image
    func resized(to size: CGSize) -> NSImage {
        let imageSize = self.size
        let aspectRatio = imageSize.width / imageSize.height
        
        var newSize = size
        if aspectRatio > 1 {
            // Landscape
            newSize.height = size.width / aspectRatio
        } else {
            // Portrait
            newSize.width = size.height * aspectRatio
        }
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        
        let rect = NSRect(origin: .zero, size: newSize)
        draw(in: rect, from: NSRect(origin: .zero, size: imageSize), operation: .copy, fraction: 1.0)
        
        resizedImage.unlockFocus()
        return resizedImage
    }
}
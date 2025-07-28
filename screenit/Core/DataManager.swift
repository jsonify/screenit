import Foundation
import CoreData
import AppKit
import OSLog
import SwiftUI

/// Manages capture history data operations and provides SwiftUI integration
final class DataManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var recentCaptures: [CaptureItem] = []
    @Published var isLoading = false
    
    // MARK: - Properties
    
    private let persistenceManager = PersistenceManager.shared
    private let logger = Logger(subsystem: "com.screenit.app", category: "DataManager")
    
    /// Maximum number of captures to retain (configurable)
    var captureRetentionLimit: Int = 10 {
        didSet {
            enforceRetentionLimit()
        }
    }
    
    // MARK: - Initialization
    
    init() {
        loadRecentCaptures()
    }
    
    // MARK: - Capture Management
    
    /// Saves a new capture with annotations to the persistent store
    /// - Parameters:
    ///   - image: The captured image
    ///   - annotations: Array of annotations to save with the capture
    ///   - completion: Completion handler with success/failure result
    func saveCaptureWithAnnotations(
        _ image: NSImage,
        annotations: [Annotation] = [],
        completion: @escaping (Result<CaptureItem, Error>) -> Void
    ) {
        isLoading = true
        
        persistenceManager.performBackgroundTask { context in
            let _ = CaptureItem.create(
                in: context,
                with: image,
                annotations: annotations
            )
            
            self.logger.info("Created capture item with \(annotations.count) annotations")
            
        } completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    self?.loadRecentCaptures()
                    self?.enforceRetentionLimit()
                    
                    // Find the newly created item for the completion handler
                    if let newestItem = self?.recentCaptures.first {
                        completion(.success(newestItem))
                    } else {
                        completion(.failure(DataManagerError.captureNotFound))
                    }
                    
                case .failure(let error):
                    self?.logger.error("Failed to save capture: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Loads recent captures from Core Data
    func loadRecentCaptures() {
        let request: NSFetchRequest<CaptureItem> = CaptureItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CaptureItem.timestamp, ascending: false)]
        request.fetchLimit = captureRetentionLimit * 2 // Fetch more for retention management
        
        do {
            let captures = try persistenceManager.viewContext.fetch(request)
            self.recentCaptures = captures
            logger.debug("Loaded \(captures.count) recent captures")
        } catch {
            logger.error("Failed to load recent captures: \(error.localizedDescription)")
            self.recentCaptures = []
        }
    }
    
    /// Deletes a specific capture item
    /// - Parameter captureItem: The capture item to delete
    func deleteCaptureItem(_ captureItem: CaptureItem) {
        persistenceManager.performBackgroundTask { context in
            // Find the object in the background context
            guard let objectID = captureItem.objectID.isTemporaryID ? nil : captureItem.objectID,
                  let backgroundItem = try? context.existingObject(with: objectID) as? CaptureItem else {
                self.logger.error("Could not find capture item in background context")
                return
            }
            
            context.delete(backgroundItem)
            self.logger.info("Deleted capture item: \(captureItem.id?.uuidString ?? "unknown")")
            
        } completion: { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.loadRecentCaptures()
                case .failure(let error):
                    self?.logger.error("Failed to delete capture item: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Exports a capture item to the specified URL
    /// - Parameters:
    ///   - captureItem: The capture item to export
    ///   - url: Destination URL for the exported image
    ///   - completion: Completion handler with success/failure result
    func exportCaptureItem(
        _ captureItem: CaptureItem,
        to url: URL,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let image = captureItem.image else {
                DispatchQueue.main.async {
                    completion(.failure(DataManagerError.imageDataCorrupted))
                }
                return
            }
            
            // Render image with annotations if they exist
            let finalImage = self.renderImageWithAnnotations(image, captureItem: captureItem)
            
            do {
                if let imageData = finalImage.pngData {
                    try imageData.write(to: url)
                    
                    DispatchQueue.main.async {
                        self.logger.info("Exported capture to: \(url.path)")
                        completion(.success(()))
                    }
                } else {
                    throw DataManagerError.imageExportFailed
                }
            } catch {
                DispatchQueue.main.async {
                    self.logger.error("Failed to export capture: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Copies a capture item to the clipboard
    /// - Parameter captureItem: The capture item to copy
    func copyToClipboard(_ captureItem: CaptureItem) {
        guard let image = captureItem.image else {
            logger.error("Failed to load image for clipboard copy")
            return
        }
        
        // Render image with annotations
        let finalImage = renderImageWithAnnotations(image, captureItem: captureItem)
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([finalImage])
        
        logger.info("Copied capture to clipboard: \(captureItem.id?.uuidString ?? "unknown")")
    }
    
    // MARK: - Storage Management
    
    /// Enforces the retention limit by removing oldest captures
    private func enforceRetentionLimit() {
        guard recentCaptures.count > captureRetentionLimit else { return }
        
        let itemsToDelete = recentCaptures.suffix(recentCaptures.count - captureRetentionLimit)
        
        persistenceManager.performBackgroundTask { context in
            for item in itemsToDelete {
                guard let objectID = item.objectID.isTemporaryID ? nil : item.objectID,
                      let backgroundItem = try? context.existingObject(with: objectID) as? CaptureItem else {
                    continue
                }
                
                context.delete(backgroundItem)
            }
            
            self.logger.info("Removed \(itemsToDelete.count) old captures to enforce retention limit")
            
        } completion: { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.loadRecentCaptures()
                case .failure(let error):
                    self?.logger.error("Failed to enforce retention limit: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Image Rendering
    
    /// Renders an image with its annotations overlaid
    /// - Parameters:
    ///   - image: Base image
    ///   - captureItem: Capture item containing annotations
    /// - Returns: Image with annotations rendered
    private func renderImageWithAnnotations(_ image: NSImage, captureItem: CaptureItem) -> NSImage {
        let annotations = captureItem.domainAnnotations
        
        // If no annotations, return original image
        guard !annotations.isEmpty else { return image }
        
        // Create a new image with annotations rendered
        let finalImage = NSImage(size: image.size)
        finalImage.lockFocus()
        
        // Draw the base image
        image.draw(in: NSRect(origin: .zero, size: image.size))
        
        // TODO: Render annotations here
        // This would require integration with the existing AnnotationEngine
        // For now, return the base image
        
        finalImage.unlockFocus()
        return finalImage
    }
}

// MARK: - Error Types

enum DataManagerError: LocalizedError {
    case captureNotFound
    case imageDataCorrupted
    case imageExportFailed
    
    var errorDescription: String? {
        switch self {
        case .captureNotFound:
            return "Capture item not found"
        case .imageDataCorrupted:
            return "Image data is corrupted or unreadable"
        case .imageExportFailed:
            return "Failed to export image data"
        }
    }
}

// MARK: - Singleton Access

extension DataManager {
    /// Shared instance for application-wide use
    static let shared = DataManager()
}

// MARK: - NSImage Extension

private extension NSImage {
    var pngData: Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(using: .png, properties: [:])
    }
}
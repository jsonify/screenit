//
//  DataManager.swift
//  screenit
//
//  Created by Jason Rueckert on 7/15/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var captureItems: [CaptureItem] = []
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreData")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {
        loadCaptureItems()
    }
    
    func save() {
        let context = viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                loadCaptureItems()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    func loadCaptureItems() {
        let request: NSFetchRequest<CaptureItem> = CaptureItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CaptureItem.timestamp, ascending: false)]
        request.fetchLimit = 10
        
        do {
            captureItems = try viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    func addCaptureItem(image: NSImage, annotations: [AnnotationData] = []) {
        let context = viewContext
        let captureItem = CaptureItem(context: context)
        
        captureItem.id = UUID()
        captureItem.timestamp = Date()
        captureItem.width = Int32(image.size.width)
        captureItem.height = Int32(image.size.height)
        
        if let imageData = image.tiffRepresentation {
            captureItem.imageData = imageData
            captureItem.fileSize = Int64(imageData.count)
            
            if let thumbnail = createThumbnail(from: image) {
                captureItem.thumbnailData = thumbnail.tiffRepresentation
            }
        }
        
        for annotationData in annotations {
            let annotation = Annotation(context: context)
            annotation.id = UUID()
            annotation.type = annotationData.type.rawValue
            annotation.positionX = annotationData.position.x
            annotation.positionY = annotationData.position.y
            annotation.sizeWidth = annotationData.size.width
            annotation.sizeHeight = annotationData.size.height
            annotation.color = annotationData.color
            annotation.thickness = annotationData.thickness
            annotation.text = annotationData.text
            annotation.fontSize = annotationData.fontSize ?? 16.0
            annotation.captureItem = captureItem
        }
        
        save()
        cleanupOldCaptures()
    }
    
    func deleteCaptureItem(_ captureItem: CaptureItem) {
        viewContext.delete(captureItem)
        save()
    }
    
    func deleteAllCaptureItems() {
        for item in captureItems {
            viewContext.delete(item)
        }
        save()
    }
    
    private func cleanupOldCaptures() {
        let request: NSFetchRequest<CaptureItem> = CaptureItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CaptureItem.timestamp, ascending: false)]
        
        do {
            let allItems = try viewContext.fetch(request)
            if allItems.count > 10 {
                let itemsToDelete = Array(allItems.dropFirst(10))
                for item in itemsToDelete {
                    viewContext.delete(item)
                }
                save()
            }
        } catch {
            print("Cleanup error: \(error)")
        }
    }
    
    private func createThumbnail(from image: NSImage, size: CGSize = CGSize(width: 150, height: 150)) -> NSImage? {
        let aspectRatio = image.size.width / image.size.height
        var thumbnailSize = size
        
        if aspectRatio > 1 {
            thumbnailSize.height = size.width / aspectRatio
        } else {
            thumbnailSize.width = size.height * aspectRatio
        }
        
        let thumbnail = NSImage(size: thumbnailSize)
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbnailSize),
                  from: NSRect(origin: .zero, size: image.size),
                  operation: .sourceOver,
                  fraction: 1.0)
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    func exportCaptureItem(_ captureItem: CaptureItem, to url: URL) -> Bool {
        guard let imageData = captureItem.imageData else { return false }
        
        do {
            try imageData.write(to: url)
            return true
        } catch {
            print("Export error: \(error)")
            return false
        }
    }
    
    func copyToClipboard(_ captureItem: CaptureItem) {
        guard let imageData = captureItem.imageData,
              let image = NSImage(data: imageData) else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}
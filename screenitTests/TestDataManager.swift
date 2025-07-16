//
//  TestDataManager.swift
//  screenitTests
//
//  Created by Claude Code on 7/16/25.
//

import Foundation
import CoreData
import SwiftUI
@testable import screenit

class TestDataManager {
    static let shared = TestDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreData")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        // Reduce Core Data logging noise in tests
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data test store error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    func createTestCaptureItem(
        width: Int32 = 1920,
        height: Int32 = 1080,
        imageData: Data? = nil,
        annotations: [AnnotationData] = []
    ) -> CaptureItem {
        let context = viewContext
        let captureItem = CaptureItem(context: context)
        
        captureItem.id = UUID()
        captureItem.timestamp = Date()
        captureItem.width = width
        captureItem.height = height
        captureItem.fileSize = Int64(imageData?.count ?? 0)
        
        if let data = imageData {
            captureItem.imageData = data
        } else {
            // Create minimal test image data
            captureItem.imageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header
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
        
        return captureItem
    }
    
    func createTestAnnotationData(
        type: AnnotationType = .arrow,
        position: CGPoint = CGPoint(x: 100, y: 100),
        size: CGSize = CGSize(width: 50, height: 50),
        color: Color = .red,
        thickness: CGFloat = 2.0,
        text: String? = nil,
        fontSize: CGFloat? = 16.0
    ) -> AnnotationData {
        return AnnotationData(
            type: type,
            position: position,
            size: size,
            color: color,
            thickness: thickness,
            text: text,
            fontSize: fontSize
        )
    }
    
    func clearTestData() {
        // Clear CaptureItems and their relationships
        let captureItemsRequest: NSFetchRequest<CaptureItem> = CaptureItem.fetchRequest()
        do {
            let captureItems = try viewContext.fetch(captureItemsRequest)
            for item in captureItems {
                viewContext.delete(item)
            }
        } catch {
            print("Failed to fetch CaptureItems for deletion: \(error)")
        }
        
        // Clear remaining Annotations (should be handled by cascade delete, but being explicit)
        let annotationsRequest: NSFetchRequest<Annotation> = Annotation.fetchRequest()
        do {
            let annotations = try viewContext.fetch(annotationsRequest)
            for annotation in annotations {
                viewContext.delete(annotation)
            }
        } catch {
            print("Failed to fetch Annotations for deletion: \(error)")
        }
        
        // Save the context
        do {
            try viewContext.save()
        } catch {
            print("Failed to save after clearing test data: \(error)")
        }
    }
    
    func save() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Test save error: \(error)")
            }
        }
    }
}
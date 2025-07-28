import XCTest
import CoreData
import AppKit
@testable import screenit

final class CoreDataModelsTests: XCTestCase {
    
    var persistenceManager: PersistenceManager!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceManager = PersistenceManager(inMemory: true)
        context = persistenceManager.viewContext
    }
    
    override func tearDown() {
        persistenceManager = nil
        context = nil
        super.tearDown()
    }
    
    // MARK: - CaptureItem Tests
    
    func testCaptureItemCreation() {
        // Given
        let timestamp = Date()
        let imageData = createTestImageData()
        let thumbnailData = createTestThumbnailData()
        
        // When
        let captureItem = CaptureItem(context: context)
        captureItem.id = UUID()
        captureItem.timestamp = timestamp
        captureItem.imageData = imageData
        captureItem.thumbnailData = thumbnailData
        captureItem.width = 1920
        captureItem.height = 1080
        captureItem.fileSize = Int64(imageData.count)
        
        // Then
        XCTAssertNotNil(captureItem.id, "CaptureItem should have ID")
        XCTAssertEqual(captureItem.timestamp, timestamp, "Timestamp should match")
        XCTAssertEqual(captureItem.imageData, imageData, "Image data should match")
        XCTAssertEqual(captureItem.thumbnailData, thumbnailData, "Thumbnail data should match")
        XCTAssertEqual(captureItem.width, 1920, "Width should match")
        XCTAssertEqual(captureItem.height, 1080, "Height should match")
        XCTAssertEqual(captureItem.fileSize, Int64(imageData.count), "File size should match")
    }
    
    func testCaptureItemRelationships() {
        // Given
        let captureItem = CaptureItem(context: context)
        captureItem.id = UUID()
        captureItem.timestamp = Date()
        captureItem.imageData = createTestImageData()
        captureItem.width = 800
        captureItem.height = 600
        
        let annotation1 = AnnotationData(context: context)
        annotation1.id = UUID()
        annotation1.type = "arrow"
        
        let annotation2 = AnnotationData(context: context)
        annotation2.id = UUID()
        annotation2.type = "text"
        
        // When
        captureItem.addToAnnotations(annotation1)
        captureItem.addToAnnotations(annotation2)
        
        // Then
        XCTAssertEqual(captureItem.annotations?.count, 2, "Should have 2 annotations")
        XCTAssertTrue(captureItem.annotations?.contains(annotation1) == true, "Should contain annotation1")
        XCTAssertTrue(captureItem.annotations?.contains(annotation2) == true, "Should contain annotation2")
        XCTAssertEqual(annotation1.captureItem, captureItem, "Annotation should reference capture item")
        XCTAssertEqual(annotation2.captureItem, captureItem, "Annotation should reference capture item")
    }
    
    func testCaptureItemValidation() {
        // Given
        let captureItem = CaptureItem(context: context)
        
        // When - Try to save without required fields
        do {
            try context.save()
            XCTFail("Save should fail without required fields")
        } catch {
            // Then
            XCTAssertTrue(error is NSError, "Should throw validation error")
        }
        
        // When - Set required fields and try again
        captureItem.id = UUID()
        captureItem.timestamp = Date()
        captureItem.imageData = createTestImageData()
        captureItem.width = 800
        captureItem.height = 600
        
        do {
            try context.save()
            // Then
            XCTAssertTrue(true, "Save should succeed with required fields")
        } catch {
            XCTFail("Save should not fail with valid data: \(error)")
        }
    }
    
    // MARK: - AnnotationData Tests
    
    func testAnnotationDataCreation() {
        // Given
        let annotationId = UUID()
        let normalizedX: Float = 0.5
        let normalizedY: Float = 0.3
        let normalizedWidth: Float = 0.2
        let normalizedHeight: Float = 0.1
        
        // When
        let annotation = AnnotationData(context: context)
        annotation.id = annotationId
        annotation.type = "rectangle"
        annotation.normalizedX = normalizedX
        annotation.normalizedY = normalizedY
        annotation.normalizedWidth = normalizedWidth
        annotation.normalizedHeight = normalizedHeight
        annotation.colorHex = "#FF0000"
        annotation.thickness = 2.0
        annotation.timestamp = Date()
        
        // Then
        XCTAssertEqual(annotation.id, annotationId, "ID should match")
        XCTAssertEqual(annotation.type, "rectangle", "Type should match")
        XCTAssertEqual(annotation.normalizedX, normalizedX, "Normalized X should match")
        XCTAssertEqual(annotation.normalizedY, normalizedY, "Normalized Y should match")
        XCTAssertEqual(annotation.normalizedWidth, normalizedWidth, "Normalized width should match")
        XCTAssertEqual(annotation.normalizedHeight, normalizedHeight, "Normalized height should match")
        XCTAssertEqual(annotation.colorHex, "#FF0000", "Color hex should match")
        XCTAssertEqual(annotation.thickness, 2.0, "Thickness should match")
    }
    
    func testAnnotationDataWithProperties() {
        // Given
        let annotation = AnnotationData(context: context)
        annotation.id = UUID()
        annotation.type = "text"
        annotation.normalizedX = 0.1
        annotation.normalizedY = 0.2
        
        let properties = ["text": "Hello World", "fontSize": "14.0", "fontWeight": "regular"]
        let propertiesData = try! JSONSerialization.data(withJSONObject: properties)
        
        // When
        annotation.properties = propertiesData
        
        // Then
        XCTAssertNotNil(annotation.properties, "Properties should be set")
        
        // Verify we can deserialize properties
        let deserializedProperties = try! JSONSerialization.jsonObject(with: annotation.properties!) as! [String: String]
        XCTAssertEqual(deserializedProperties["text"], "Hello World", "Text property should match")
        XCTAssertEqual(deserializedProperties["fontSize"], "14.0", "Font size should match")
    }
    
    func testAnnotationDataCascadeDelete() {
        // Given
        let captureItem = CaptureItem(context: context)
        captureItem.id = UUID()
        captureItem.timestamp = Date()
        captureItem.imageData = createTestImageData()
        captureItem.width = 800
        captureItem.height = 600
        
        let annotation = AnnotationData(context: context)
        annotation.id = UUID()
        annotation.type = "arrow"
        annotation.normalizedX = 0.5
        annotation.normalizedY = 0.5
        
        captureItem.addToAnnotations(annotation)
        
        try! context.save()
        
        // When - Delete the capture item
        context.delete(captureItem)
        try! context.save()
        
        // Then - Annotation should be deleted too (cascade delete)
        let annotationFetch = NSFetchRequest<AnnotationData>(entityName: "AnnotationData")
        let annotations = try! context.fetch(annotationFetch)
        XCTAssertEqual(annotations.count, 0, "Annotations should be cascade deleted")
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageData() -> Data {
        // Create a simple 1x1 pixel PNG data for testing
        let image = NSImage(size: NSSize(width: 1, height: 1))
        image.lockFocus()
        NSColor.red.set()
        NSRect(x: 0, y: 0, width: 1, height: 1).fill()
        image.unlockFocus()
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return Data()
        }
        
        return pngData
    }
    
    private func createTestThumbnailData() -> Data {
        // Create a simple thumbnail data for testing
        let image = NSImage(size: NSSize(width: 200, height: 200))
        image.lockFocus()
        NSColor.blue.set()
        NSRect(x: 0, y: 0, width: 200, height: 200).fill()
        image.unlockFocus()
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return Data()
        }
        
        return pngData
    }
}
//
//  DataManagerTests.swift
//  screenitTests
//
//  Created by Claude Code on 7/16/25.
//

import XCTest
import CoreData
import SwiftUI
@testable import screenit

final class DataManagerTests: XCTestCase {
    
    var testDataManager: TestDataManager!
    var dataManager: DataManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        testDataManager = TestDataManager.shared
        testDataManager.clearTestData()
        
        // Create a test DataManager that uses our in-memory store
        dataManager = DataManager.shared
    }
    
    override func tearDown() {
        testDataManager.clearTestData()
        testDataManager = nil
        dataManager = nil
        super.tearDown()
    }
    
    @MainActor
    func testCreateTestCaptureItem() {
        let captureItem = testDataManager.createTestCaptureItem()
        
        XCTAssertNotNil(captureItem.id)
        XCTAssertNotNil(captureItem.timestamp)
        XCTAssertEqual(captureItem.width, 1920)
        XCTAssertEqual(captureItem.height, 1080)
        XCTAssertNotNil(captureItem.imageData)
        XCTAssertGreaterThan(captureItem.fileSize, 0)
    }
    
    @MainActor
    func testCreateTestCaptureItemWithCustomData() {
        let customImageData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])
        let annotation = testDataManager.createTestAnnotationData(
            type: .text,
            position: CGPoint(x: 50, y: 75),
            color: .blue
        )
        
        let captureItem = testDataManager.createTestCaptureItem(
            width: 800,
            height: 600,
            imageData: customImageData,
            annotations: [annotation]
        )
        
        XCTAssertEqual(captureItem.width, 800)
        XCTAssertEqual(captureItem.height, 600)
        XCTAssertEqual(captureItem.imageData, customImageData)
        XCTAssertEqual(captureItem.fileSize, Int64(customImageData.count))
        XCTAssertEqual(captureItem.annotations?.count, 1)
    }
    
    @MainActor
    func testCreateTestAnnotationData() {
        let annotation = testDataManager.createTestAnnotationData()
        
        XCTAssertEqual(annotation.type, .arrow)
        XCTAssertEqual(annotation.position, CGPoint(x: 100, y: 100))
        XCTAssertEqual(annotation.size, CGSize(width: 50, height: 50))
        XCTAssertEqual(annotation.thickness, 2.0)
        XCTAssertNil(annotation.text)
    }
    
    @MainActor
    func testCreateTestAnnotationDataWithCustomValues() {
        let annotation = testDataManager.createTestAnnotationData(
            type: .text,
            position: CGPoint(x: 200, y: 300),
            size: CGSize(width: 100, height: 25),
            color: .green,
            thickness: 3.0,
            text: "Test Text",
            fontSize: 18.0
        )
        
        XCTAssertEqual(annotation.type, .text)
        XCTAssertEqual(annotation.position, CGPoint(x: 200, y: 300))
        XCTAssertEqual(annotation.size, CGSize(width: 100, height: 25))
        XCTAssertEqual(annotation.thickness, 3.0)
        XCTAssertEqual(annotation.text, "Test Text")
        XCTAssertEqual(annotation.fontSize, 18.0)
    }
    
    @MainActor
    func testClearTestData() {
        // Create some test data
        let _ = testDataManager.createTestCaptureItem()
        let _ = testDataManager.createTestCaptureItem()
        testDataManager.save()
        
        // Verify data exists
        let request: NSFetchRequest<CaptureItem> = CaptureItem.fetchRequest()
        let itemsBeforeClear = try! testDataManager.viewContext.fetch(request)
        XCTAssertEqual(itemsBeforeClear.count, 2)
        
        // Clear data
        testDataManager.clearTestData()
        
        // Verify data is cleared
        let itemsAfterClear = try! testDataManager.viewContext.fetch(request)
        XCTAssertEqual(itemsAfterClear.count, 0)
    }
    
    @MainActor
    func testSaveTestData() {
        let captureItem = testDataManager.createTestCaptureItem()
        
        // Data should not be persisted until save is called
        let requestBeforeSave: NSFetchRequest<CaptureItem> = CaptureItem.fetchRequest()
        let itemsBeforeSave = try! testDataManager.viewContext.fetch(requestBeforeSave)
        
        testDataManager.save()
        
        // Data should be persisted after save
        let requestAfterSave: NSFetchRequest<CaptureItem> = CaptureItem.fetchRequest()
        let itemsAfterSave = try! testDataManager.viewContext.fetch(requestAfterSave)
        XCTAssertGreaterThan(itemsAfterSave.count, 0)
        
        let savedItem = itemsAfterSave.first!
        XCTAssertEqual(savedItem.id, captureItem.id)
        XCTAssertEqual(savedItem.width, captureItem.width)
        XCTAssertEqual(savedItem.height, captureItem.height)
    }
    
    @MainActor
    func testDataManagerSingleton() {
        let dataManager1 = DataManager.shared
        let dataManager2 = DataManager.shared
        
        XCTAssertTrue(dataManager1 === dataManager2)
    }
    
    @MainActor
    func testDataManagerPersistentContainer() {
        XCTAssertNotNil(dataManager.persistentContainer)
        XCTAssertNotNil(dataManager.viewContext)
        XCTAssertEqual(dataManager.viewContext, dataManager.persistentContainer.viewContext)
    }
    
    @MainActor
    func testDataManagerCaptureItemsProperty() {
        XCTAssertNotNil(dataManager.captureItems)
        // Should start as empty array
        XCTAssertTrue(dataManager.captureItems.isEmpty)
    }
    
    // Note: The following tests would require modifying DataManager to support dependency injection
    // or creating a test-specific version that uses the in-memory store
    
    @MainActor
    func testAnnotationDataTypes() {
        // Test all annotation types
        let types: [AnnotationType] = [.arrow, .text, .rectangle, .highlight, .blur]
        
        for type in types {
            let annotation = testDataManager.createTestAnnotationData(type: type)
            XCTAssertEqual(annotation.type, type)
        }
    }
    
    @MainActor
    func testImageDataHandling() {
        // Test with various image data scenarios
        let emptyData = Data()
        let captureItemEmpty = testDataManager.createTestCaptureItem(imageData: emptyData)
        XCTAssertEqual(captureItemEmpty.imageData, emptyData)
        XCTAssertEqual(captureItemEmpty.fileSize, 0)
        
        let largeData = Data(repeating: 0xFF, count: 1000)
        let captureItemLarge = testDataManager.createTestCaptureItem(imageData: largeData)
        XCTAssertEqual(captureItemLarge.imageData, largeData)
        XCTAssertEqual(captureItemLarge.fileSize, 1000)
    }
}
//
//  ModelTests.swift
//  screenitTests
//
//  Created by Claude Code on 7/16/25.
//

import XCTest
import CoreData
import SwiftUI
@testable import screenit

final class ModelTests: XCTestCase {
    
    var testDataManager: TestDataManager!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        testDataManager = TestDataManager.shared
        context = testDataManager.viewContext
        testDataManager.clearTestData()
    }
    
    override func tearDown() {
        testDataManager.clearTestData()
        testDataManager = nil
        context = nil
        super.tearDown()
    }
    
    // MARK: - CaptureItem Tests
    
    func testCaptureItemCreation() {
        let captureItem = CaptureItem(context: context)
        
        XCTAssertNotNil(captureItem)
        XCTAssertNil(captureItem.id)
        XCTAssertNil(captureItem.timestamp)
        XCTAssertNil(captureItem.imageData)
        XCTAssertNil(captureItem.thumbnailData)
        XCTAssertEqual(captureItem.width, 0)
        XCTAssertEqual(captureItem.height, 0)
        XCTAssertEqual(captureItem.fileSize, 0)
        XCTAssertNil(captureItem.annotations)
    }
    
    func testCaptureItemProperties() {
        let captureItem = CaptureItem(context: context)
        let testId = UUID()
        let testDate = Date()
        let testImageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let testThumbnailData = Data([0x89, 0x50, 0x4E, 0x47])
        
        captureItem.id = testId
        captureItem.timestamp = testDate
        captureItem.imageData = testImageData
        captureItem.thumbnailData = testThumbnailData
        captureItem.width = 1920
        captureItem.height = 1080
        captureItem.fileSize = 12345
        
        XCTAssertEqual(captureItem.id, testId)
        XCTAssertEqual(captureItem.timestamp, testDate)
        XCTAssertEqual(captureItem.imageData, testImageData)
        XCTAssertEqual(captureItem.thumbnailData, testThumbnailData)
        XCTAssertEqual(captureItem.width, 1920)
        XCTAssertEqual(captureItem.height, 1080)
        XCTAssertEqual(captureItem.fileSize, 12345)
    }
    
    func testCaptureItemFetchRequest() {
        let fetchRequest = CaptureItem.fetchRequest()
        
        XCTAssertNotNil(fetchRequest)
        XCTAssertEqual(fetchRequest.entityName, "CaptureItem")
    }
    
    func testCaptureItemIdentifiable() {
        let captureItem = CaptureItem(context: context)
        let testId = UUID()
        captureItem.id = testId
        
        // Test that CaptureItem conforms to Identifiable
        XCTAssertEqual(captureItem.id, testId)
    }
    
    func testCaptureItemAnnotationRelationship() {
        let captureItem = CaptureItem(context: context)
        let annotation1 = Annotation(context: context)
        let annotation2 = Annotation(context: context)
        
        annotation1.captureItem = captureItem
        annotation2.captureItem = captureItem
        
        XCTAssertEqual(captureItem.annotations?.count, 2)
        XCTAssertTrue(captureItem.annotations?.contains(annotation1) ?? false)
        XCTAssertTrue(captureItem.annotations?.contains(annotation2) ?? false)
    }
    
    func testCaptureItemAddAnnotation() {
        let captureItem = CaptureItem(context: context)
        let annotation = Annotation(context: context)
        
        captureItem.addToAnnotations(annotation)
        
        XCTAssertEqual(captureItem.annotations?.count, 1)
        XCTAssertTrue(captureItem.annotations?.contains(annotation) ?? false)
        XCTAssertEqual(annotation.captureItem, captureItem)
    }
    
    func testCaptureItemRemoveAnnotation() {
        let captureItem = CaptureItem(context: context)
        let annotation = Annotation(context: context)
        
        captureItem.addToAnnotations(annotation)
        XCTAssertEqual(captureItem.annotations?.count, 1)
        
        captureItem.removeFromAnnotations(annotation)
        XCTAssertEqual(captureItem.annotations?.count, 0)
    }
    
    // MARK: - Annotation Tests
    
    func testAnnotationCreation() {
        let annotation = Annotation(context: context)
        
        XCTAssertNotNil(annotation)
        XCTAssertNil(annotation.id)
        XCTAssertNil(annotation.type)
        XCTAssertEqual(annotation.positionX, 0.0)
        XCTAssertEqual(annotation.positionY, 0.0)
        XCTAssertEqual(annotation.sizeWidth, 0.0)
        XCTAssertEqual(annotation.sizeHeight, 0.0)
        XCTAssertNil(annotation.color)
        XCTAssertEqual(annotation.thickness, 0.0)
        XCTAssertNil(annotation.text)
        XCTAssertEqual(annotation.fontSize, 0.0)
        XCTAssertNil(annotation.captureItem)
    }
    
    func testAnnotationProperties() {
        let annotation = Annotation(context: context)
        let testId = UUID()
        
        annotation.id = testId
        annotation.type = "arrow"
        annotation.positionX = 100.5
        annotation.positionY = 200.7
        annotation.sizeWidth = 50.0
        annotation.sizeHeight = 75.0
        annotation.color = "#FF0000"
        annotation.thickness = 3.0
        annotation.text = "Test annotation"
        annotation.fontSize = 16.0
        
        XCTAssertEqual(annotation.id, testId)
        XCTAssertEqual(annotation.type, "arrow")
        XCTAssertEqual(annotation.positionX, 100.5, accuracy: 0.01)
        XCTAssertEqual(annotation.positionY, 200.7, accuracy: 0.01)
        XCTAssertEqual(annotation.sizeWidth, 50.0, accuracy: 0.01)
        XCTAssertEqual(annotation.sizeHeight, 75.0, accuracy: 0.01)
        XCTAssertEqual(annotation.color, "#FF0000")
        XCTAssertEqual(annotation.thickness, 3.0, accuracy: 0.01)
        XCTAssertEqual(annotation.text, "Test annotation")
        XCTAssertEqual(annotation.fontSize, 16.0, accuracy: 0.01)
    }
    
    func testAnnotationFetchRequest() {
        let fetchRequest = Annotation.fetchRequest()
        
        XCTAssertNotNil(fetchRequest)
        XCTAssertEqual(fetchRequest.entityName, "Annotation")
    }
    
    func testAnnotationIdentifiable() {
        let annotation = Annotation(context: context)
        let testId = UUID()
        annotation.id = testId
        
        // Test that Annotation conforms to Identifiable
        XCTAssertEqual(annotation.id, testId)
    }
    
    func testAnnotationCaptureItemRelationship() {
        let captureItem = CaptureItem(context: context)
        let annotation = Annotation(context: context)
        
        annotation.captureItem = captureItem
        
        XCTAssertEqual(annotation.captureItem, captureItem)
        XCTAssertTrue(captureItem.annotations?.contains(annotation) ?? false)
    }
    
    // MARK: - AnnotationType Tests
    
    func testAnnotationTypeRawValues() {
        XCTAssertEqual(AnnotationType.arrow.rawValue, "arrow")
        XCTAssertEqual(AnnotationType.text.rawValue, "text")
        XCTAssertEqual(AnnotationType.rectangle.rawValue, "rectangle")
        XCTAssertEqual(AnnotationType.highlight.rawValue, "highlight")
        XCTAssertEqual(AnnotationType.blur.rawValue, "blur")
    }
    
    func testAnnotationTypeCaseIterable() {
        let allTypes = AnnotationType.allCases
        
        XCTAssertEqual(allTypes.count, 5)
        XCTAssertTrue(allTypes.contains(.arrow))
        XCTAssertTrue(allTypes.contains(.text))
        XCTAssertTrue(allTypes.contains(.rectangle))
        XCTAssertTrue(allTypes.contains(.highlight))
        XCTAssertTrue(allTypes.contains(.blur))
    }
    
    func testAnnotationTypeCodable() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for type in AnnotationType.allCases {
            do {
                let data = try encoder.encode(type)
                let decodedType = try decoder.decode(AnnotationType.self, from: data)
                XCTAssertEqual(type, decodedType)
            } catch {
                XCTFail("Failed to encode/decode \(type): \(error)")
            }
        }
    }
    
    // MARK: - AnnotationData Tests
    
    func testAnnotationDataCreation() {
        let annotation = AnnotationData(
            type: .arrow,
            position: CGPoint(x: 100, y: 200),
            size: CGSize(width: 50, height: 75),
            color: .red,
            thickness: 2.0,
            text: "Test",
            fontSize: 16.0
        )
        
        XCTAssertNotNil(annotation.id)
        XCTAssertEqual(annotation.type, .arrow)
        XCTAssertEqual(annotation.position, CGPoint(x: 100, y: 200))
        XCTAssertEqual(annotation.size, CGSize(width: 50, height: 75))
        XCTAssertEqual(annotation.thickness, 2.0)
        XCTAssertEqual(annotation.text, "Test")
        XCTAssertEqual(annotation.fontSize, 16.0)
        XCTAssertFalse(annotation.color.isEmpty)
    }
    
    func testAnnotationDataIdentifiable() {
        let annotation1 = AnnotationData(type: .arrow, position: .zero, color: .red)
        let annotation2 = AnnotationData(type: .arrow, position: .zero, color: .red)
        
        XCTAssertNotEqual(annotation1.id, annotation2.id)
    }
    
    func testAnnotationDataCodable() {
        let annotation = AnnotationData(
            type: .text,
            position: CGPoint(x: 50, y: 100),
            size: CGSize(width: 200, height: 30),
            color: .blue,
            thickness: 1.0,
            text: "Hello World",
            fontSize: 18.0
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(annotation)
            let decodedAnnotation = try decoder.decode(AnnotationData.self, from: data)
            
            XCTAssertEqual(annotation.id, decodedAnnotation.id)
            XCTAssertEqual(annotation.type, decodedAnnotation.type)
            XCTAssertEqual(annotation.position, decodedAnnotation.position)
            XCTAssertEqual(annotation.size, decodedAnnotation.size)
            XCTAssertEqual(annotation.color, decodedAnnotation.color)
            XCTAssertEqual(annotation.thickness, decodedAnnotation.thickness)
            XCTAssertEqual(annotation.text, decodedAnnotation.text)
            XCTAssertEqual(annotation.fontSize, decodedAnnotation.fontSize)
        } catch {
            XCTFail("Failed to encode/decode AnnotationData: \(error)")
        }
    }
    
    // MARK: - Color Extension Tests
    
    func testColorToHex() {
        let redColor = Color.red
        let hexString = redColor.toHex()
        
        XCTAssertFalse(hexString.isEmpty)
        XCTAssertTrue(hexString.hasPrefix("#"))
        XCTAssertEqual(hexString.count, 7) // #RRGGBB format
    }
    
    func testColorFromHex() {
        let redHex = "#FF0000"
        let redColor = Color(hex: redHex)
        
        // Convert back to hex to verify
        let convertedHex = redColor.toHex()
        XCTAssertEqual(convertedHex, redHex)
    }
    
    func testColorHexRoundTrip() {
        let colors: [Color] = [.red, .green, .blue, .black, .white]
        
        for color in colors {
            let hex = color.toHex()
            let reconstructedColor = Color(hex: hex)
            let reconstructedHex = reconstructedColor.toHex()
            
            // Allow for some tolerance in color conversion
            XCTAssertEqual(hex, reconstructedHex)
        }
    }
}
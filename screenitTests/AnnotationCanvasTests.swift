import XCTest
import SwiftUI
@testable import screenit

@MainActor
final class AnnotationCanvasTests: XCTestCase {
    
    var annotationEngine: AnnotationEngine!
    var canvas: AnnotationCanvas!
    
    override func setUp() async throws {
        try await super.setUp()
        annotationEngine = AnnotationEngine()
        canvas = AnnotationCanvas(
            annotations: annotationEngine.annotations,
            engine: annotationEngine,
            imageSize: CGSize(width: 800, height: 600)
        )
    }
    
    override func tearDown() async throws {
        annotationEngine = nil
        canvas = nil
        try await super.tearDown()
    }
    
    // MARK: - Canvas Initialization Tests
    
    func testCanvasInitialization() {
        XCTAssertNotNil(canvas)
        XCTAssertEqual(canvas.imageSize.width, 800)
        XCTAssertEqual(canvas.imageSize.height, 600)
        XCTAssertTrue(canvas.annotations.isEmpty)
    }
    
    func testCanvasWithAnnotations() {
        // Add test annotation
        let testAnnotation = Annotation(
            type: .arrow,
            properties: ArrowProperties(),
            geometry: ArrowGeometry(startPoint: CGPoint(x: 10, y: 10), endPoint: CGPoint(x: 50, y: 50))
        )
        annotationEngine.addAnnotation(testAnnotation)
        
        let canvasWithAnnotations = AnnotationCanvas(
            annotations: annotationEngine.annotations,
            engine: annotationEngine,
            imageSize: CGSize(width: 800, height: 600)
        )
        
        XCTAssertEqual(canvasWithAnnotations.annotations.count, 1)
        XCTAssertEqual(canvasWithAnnotations.annotations.first?.type, .arrow)
    }
    
    // MARK: - Drawing Event Tests
    
    func testDrawingEventHandling() {
        // Select arrow tool
        annotationEngine.selectTool(.arrow)
        
        // Simulate draw start
        let startPoint = CGPoint(x: 100, y: 100)
        canvas.handleDrawStart(at: startPoint)
        
        XCTAssertNotNil(canvas.currentDrawing)
        XCTAssertEqual(canvas.currentDrawing?.startPoint, startPoint)
    }
    
    func testDrawingEventUpdate() {
        // Select arrow tool and start drawing
        annotationEngine.selectTool(.arrow)
        let startPoint = CGPoint(x: 100, y: 100)
        canvas.handleDrawStart(at: startPoint)
        
        // Update drawing
        let updatePoint = CGPoint(x: 150, y: 150)
        canvas.handleDrawUpdate(at: updatePoint)
        
        XCTAssertEqual(canvas.currentDrawing?.currentPoint, updatePoint)
    }
    
    func testDrawingEventEnd() {
        // Select arrow tool and start drawing
        annotationEngine.selectTool(.arrow)
        let startPoint = CGPoint(x: 100, y: 100)
        canvas.handleDrawStart(at: startPoint)
        
        // End drawing
        let endPoint = CGPoint(x: 200, y: 200)
        canvas.handleDrawEnd(at: endPoint)
        
        XCTAssertNil(canvas.currentDrawing)
        XCTAssertEqual(annotationEngine.annotations.count, 1)
        XCTAssertEqual(annotationEngine.annotations.first?.type, .arrow)
    }
    
    // MARK: - Canvas Drawing State Tests
    
    func testCurrentDrawingState() {
        XCTAssertNil(canvas.currentDrawing)
        XCTAssertFalse(canvas.isDrawing)
        
        // Start drawing
        annotationEngine.selectTool(.rectangle)
        canvas.handleDrawStart(at: CGPoint(x: 50, y: 50))
        
        XCTAssertNotNil(canvas.currentDrawing)
        XCTAssertTrue(canvas.isDrawing)
        
        // End drawing
        canvas.handleDrawEnd(at: CGPoint(x: 100, y: 100))
        
        XCTAssertNil(canvas.currentDrawing)
        XCTAssertFalse(canvas.isDrawing)
    }
    
    func testCancelDrawing() {
        // Start drawing
        annotationEngine.selectTool(.text)
        canvas.handleDrawStart(at: CGPoint(x: 75, y: 75))
        
        XCTAssertTrue(canvas.isDrawing)
        
        // Cancel drawing
        canvas.cancelCurrentDrawing()
        
        XCTAssertFalse(canvas.isDrawing)
        XCTAssertNil(canvas.currentDrawing)
        XCTAssertEqual(annotationEngine.annotations.count, 0)
    }
    
    // MARK: - Coordinate Transformation Tests
    
    func testCoordinateTransformation() {
        let canvasPoint = CGPoint(x: 400, y: 300)
        let transformedPoint = canvas.transformToImageCoordinates(canvasPoint)
        
        // For a 800x600 image, center point should remain unchanged
        XCTAssertEqual(transformedPoint.x, 400, accuracy: 0.1)
        XCTAssertEqual(transformedPoint.y, 300, accuracy: 0.1)
    }
    
    func testBoundsChecking() {
        let validPoint = CGPoint(x: 400, y: 300)
        let invalidPoint = CGPoint(x: 1000, y: 700)
        
        XCTAssertTrue(canvas.isPointInBounds(validPoint))
        XCTAssertFalse(canvas.isPointInBounds(invalidPoint))
    }
    
    // MARK: - Performance Tests
    
    func testCanvasRenderingPerformance() {
        // Add multiple annotations
        for i in 0..<50 {
            let annotation = Annotation(
                type: .arrow,
                properties: ArrowProperties(),
                geometry: ArrowGeometry(
                    startPoint: CGPoint(x: i * 10, y: i * 5),
                    endPoint: CGPoint(x: i * 10 + 20, y: i * 5 + 20)
                )
            )
            annotationEngine.addAnnotation(annotation)
        }
        
        measure {
            // Test canvas rendering with many annotations
            let _ = AnnotationCanvas(
                annotations: annotationEngine.annotations,
                engine: annotationEngine,
                imageSize: CGSize(width: 800, height: 600)
            )
        }
    }
    
    // MARK: - Integration Tests
    
    func testCanvasEngineIntegration() {
        // Test that canvas properly delegates to annotation engine
        annotationEngine.selectTool(.highlight)
        
        let startPoint = CGPoint(x: 200, y: 150)
        let endPoint = CGPoint(x: 300, y: 250)
        
        canvas.handleDrawStart(at: startPoint)
        canvas.handleDrawUpdate(at: endPoint)
        canvas.handleDrawEnd(at: endPoint)
        
        XCTAssertEqual(annotationEngine.annotations.count, 1)
        XCTAssertEqual(annotationEngine.annotations.first?.type, .highlight)
        
        let geometry = annotationEngine.annotations.first?.geometry as? HighlightGeometry
        XCTAssertNotNil(geometry)
        XCTAssertEqual(geometry?.bounds.width, 100, accuracy: 0.1)
        XCTAssertEqual(geometry?.bounds.height, 100, accuracy: 0.1)
    }
}
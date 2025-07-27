import XCTest
import SwiftUI
@testable import screenit

final class CaptureAnnotationIntegrationTests: XCTestCase {
  
  var captureEngine: CaptureEngine!
  var annotationEngine: AnnotationEngine!
  
  override func setUp() {
    super.setUp()
    captureEngine = CaptureEngine()
    annotationEngine = AnnotationEngine()
  }
  
  override func tearDown() {
    captureEngine = nil
    annotationEngine = nil
    super.tearDown()
  }
  
  func testCaptureToAnnotationWorkflow() {
    // Test the basic workflow from capture to annotation
    let expectation = XCTestExpectation(description: "Capture to annotation workflow")
    
    // Mock captured image
    let testImageSize = CGSize(width: 1920, height: 1080)
    
    // Start annotation session after capture
    annotationEngine.startAnnotationSession(for: testImageSize)
    
    XCTAssertTrue(annotationEngine.isAnnotating)
    XCTAssertEqual(annotationEngine.annotations.count, 0)
    
    expectation.fulfill()
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testAnnotationOnCapturedImage() {
    let testImageSize = CGSize(width: 800, height: 600)
    
    // Start annotation session
    annotationEngine.startAnnotationSession(for: testImageSize)
    
    // Add test annotation
    let arrowAnnotation = Annotation(
      type: .arrow,
      properties: ArrowProperties(color: .red, thickness: 3.0),
      geometry: ArrowGeometry(
        startPoint: CGPoint(x: 100, y: 100),
        endPoint: CGPoint(x: 200, y: 200)
      )
    )
    
    annotationEngine.addAnnotation(arrowAnnotation)
    
    XCTAssertEqual(annotationEngine.annotations.count, 1)
    XCTAssertEqual(annotationEngine.annotations.first?.type, .arrow)
  }
  
  func testExportWithAnnotations() {
    let testImageSize = CGSize(width: 400, height: 300)
    
    // Start annotation session
    annotationEngine.startAnnotationSession(for: testImageSize)
    
    // Add multiple annotations
    let arrowAnnotation = Annotation(
      type: .arrow,
      properties: ArrowProperties(color: .red, thickness: 3.0),
      geometry: ArrowGeometry(
        startPoint: CGPoint(x: 50, y: 50),
        endPoint: CGPoint(x: 150, y: 100)
      )
    )
    
    let rectAnnotation = Annotation(
      type: .rectangle,
      properties: RectangleProperties(color: .blue, thickness: 2.0),
      geometry: RectangleGeometry(rect: CGRect(x: 200, y: 150, width: 100, height: 80))
    )
    
    annotationEngine.addAnnotation(arrowAnnotation)
    annotationEngine.addAnnotation(rectAnnotation)
    
    // End session and get annotations
    let finalAnnotations = annotationEngine.endAnnotationSession()
    
    XCTAssertEqual(finalAnnotations.count, 2)
    XCTAssertFalse(annotationEngine.isAnnotating)
  }
  
  func testAnnotationCoordinateTransformation() {
    let imageSize = CGSize(width: 1920, height: 1080)
    let canvasSize = CGSize(width: 960, height: 540) // Half size
    
    annotationEngine.startAnnotationSession(for: imageSize)
    
    // Create annotation canvas for coordinate testing
    let annotationCanvas = AnnotationCanvas(
      annotations: [],
      engine: annotationEngine,
      imageSize: imageSize
    )
    
    // Test coordinate transformation
    let imagePoint = CGPoint(x: 200, y: 200)
    let canvasPoint = annotationCanvas.transformToCanvasCoordinates(imagePoint, size: canvasSize)
    let backToImage = annotationCanvas.transformToImageCoordinates(canvasPoint)
    
    // Should transform back to original coordinates (with floating point tolerance)
    XCTAssertEqual(backToImage.x, imagePoint.x, accuracy: 1.0)
    XCTAssertEqual(backToImage.y, imagePoint.y, accuracy: 1.0)
  }
  
  func testAnnotationBoundsChecking() {
    let imageSize = CGSize(width: 800, height: 600)
    
    annotationEngine.startAnnotationSession(for: imageSize)
    
    let annotationCanvas = AnnotationCanvas(
      annotations: [],
      engine: annotationEngine,
      imageSize: imageSize
    )
    
    // Test points within bounds
    XCTAssertTrue(annotationCanvas.isPointInBounds(CGPoint(x: 400, y: 300)))
    XCTAssertTrue(annotationCanvas.isPointInBounds(CGPoint(x: 0, y: 0)))
    XCTAssertTrue(annotationCanvas.isPointInBounds(CGPoint(x: 800, y: 600)))
    
    // Test points outside bounds
    XCTAssertFalse(annotationCanvas.isPointInBounds(CGPoint(x: -10, y: 300)))
    XCTAssertFalse(annotationCanvas.isPointInBounds(CGPoint(x: 400, y: -10)))
    XCTAssertFalse(annotationCanvas.isPointInBounds(CGPoint(x: 900, y: 300)))
    XCTAssertFalse(annotationCanvas.isPointInBounds(CGPoint(x: 400, y: 700)))
  }
  
  func testAnnotationToolSelection() {
    annotationEngine.startAnnotationSession(for: CGSize(width: 800, height: 600))
    
    // Test tool registration and selection
    let arrowTool = ArrowTool()
    annotationEngine.registerTool(arrowTool)
    annotationEngine.selectTool(for: .arrow)
    
    XCTAssertNotNil(annotationEngine.selectedTool)
    XCTAssertEqual(annotationEngine.selectedTool?.type, .arrow)
  }
  
  func testImageExportWithAnnotations() {
    let testImageSize = CGSize(width: 400, height: 300)
    
    annotationEngine.startAnnotationSession(for: testImageSize)
    
    // Add test annotation
    let textAnnotation = Annotation(
      type: .text,
      properties: TextProperties(
        text: "Test Label",
        color: .black,
        fontSize: 16.0,
        fontWeight: .regular,
        backgroundColor: .white
      ),
      geometry: TextGeometry(
        position: CGPoint(x: 100, y: 100),
        size: CGSize(width: 80, height: 20)
      )
    )
    
    annotationEngine.addAnnotation(textAnnotation)
    
    // Mock export process
    let annotationsForExport = annotationEngine.annotations
    
    XCTAssertEqual(annotationsForExport.count, 1)
    XCTAssertEqual(annotationsForExport.first?.type, .text)
    
    // Verify annotation properties are preserved for export
    if let textProps = annotationsForExport.first?.properties as? TextProperties {
      XCTAssertEqual(textProps.text, "Test Label")
      XCTAssertEqual(textProps.fontSize, 16.0)
    } else {
      XCTFail("Text properties not preserved")
    }
  }
  
  func testAnnotationStatePersistence() {
    let testImageSize = CGSize(width: 600, height: 400)
    
    annotationEngine.startAnnotationSession(for: testImageSize)
    
    // Set tool state
    annotationEngine.toolState.color = .green
    annotationEngine.toolState.thickness = 5.0
    
    // Create annotation with current state
    let highlightAnnotation = Annotation(
      type: .highlight,
      properties: HighlightProperties(
        color: annotationEngine.toolState.color,
        opacity: 0.3
      ),
      geometry: HighlightGeometry(rect: CGRect(x: 50, y: 50, width: 100, height: 50))
    )
    
    annotationEngine.addAnnotation(highlightAnnotation)
    
    // Verify state is preserved in annotation
    if let highlightProps = annotationEngine.annotations.first?.properties as? HighlightProperties {
      XCTAssertEqual(highlightProps.color, .green)
      XCTAssertEqual(highlightProps.opacity, 0.3)
    } else {
      XCTFail("Highlight properties not preserved")
    }
  }
}
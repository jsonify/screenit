import XCTest
@testable import screenit

@MainActor
final class AnnotationEngineTests: XCTestCase {
    
    var annotationEngine: AnnotationEngine!
    var mockToolState: MockAnnotationToolState!
    var mockHistory: MockAnnotationHistory!
    
    override func setUp() async throws {
        annotationEngine = AnnotationEngine()
        mockToolState = MockAnnotationToolState()
        mockHistory = MockAnnotationHistory()
    }
    
    override func tearDown() async throws {
        annotationEngine = nil
        mockToolState = nil
        mockHistory = nil
    }
    
    // MARK: - Tool Registry Tests
    
    func testToolRegistration() {
        // Test that tools can be registered and retrieved
        let arrowTool = ArrowTool()
        
        annotationEngine.registerTool(arrowTool)
        
        let retrievedTool = annotationEngine.getTool(for: .arrow)
        XCTAssertNotNil(retrievedTool)
        XCTAssertTrue(retrievedTool is ArrowTool)
    }
    
    func testToolSelectionStateManagement() {
        // Test that selected tool state is properly managed
        let arrowTool = ArrowTool()
        let textTool = TextTool()
        
        annotationEngine.registerTool(arrowTool)
        annotationEngine.registerTool(textTool)
        
        // Initially no tool should be selected
        XCTAssertNil(annotationEngine.selectedTool)
        
        // Select arrow tool
        annotationEngine.selectTool(.arrow)
        XCTAssertEqual(annotationEngine.selectedTool?.type, .arrow)
        
        // Switch to text tool
        annotationEngine.selectTool(.text)
        XCTAssertEqual(annotationEngine.selectedTool?.type, .text)
    }
    
    func testToolStateConfiguration() {
        // Test that tool configuration properties are properly managed
        let initialColor = annotationEngine.toolState.color
        let initialThickness = annotationEngine.toolState.thickness
        
        // Change color
        annotationEngine.toolState.color = .red
        XCTAssertEqual(annotationEngine.toolState.color, .red)
        XCTAssertNotEqual(annotationEngine.toolState.color, initialColor)
        
        // Change thickness
        annotationEngine.toolState.thickness = 5.0
        XCTAssertEqual(annotationEngine.toolState.thickness, 5.0)
        XCTAssertNotEqual(annotationEngine.toolState.thickness, initialThickness)
    }
    
    // MARK: - Canvas Coordination Tests
    
    func testCanvasEventRouting() {
        // Test that canvas events are properly routed to selected tool
        let arrowTool = MockArrowTool()
        annotationEngine.registerTool(arrowTool)
        annotationEngine.selectTool(.arrow)
        
        let startPoint = CGPoint(x: 100, y: 100)
        let endPoint = CGPoint(x: 200, y: 200)
        
        annotationEngine.handleCanvasEvent(.drawStart(startPoint))
        XCTAssertTrue(arrowTool.drawStartCalled)
        XCTAssertEqual(arrowTool.lastStartPoint, startPoint)
        
        annotationEngine.handleCanvasEvent(.drawUpdate(endPoint))
        XCTAssertTrue(arrowTool.drawUpdateCalled)
        XCTAssertEqual(arrowTool.lastUpdatePoint, endPoint)
        
        annotationEngine.handleCanvasEvent(.drawEnd(endPoint))
        XCTAssertTrue(arrowTool.drawEndCalled)
        XCTAssertEqual(arrowTool.lastEndPoint, endPoint)
    }
    
    func testCanvasEventWithoutSelectedTool() {
        // Test that canvas events are handled gracefully when no tool is selected
        let startPoint = CGPoint(x: 100, y: 100)
        
        // Should not crash when no tool is selected
        XCTAssertNoThrow {
            annotationEngine.handleCanvasEvent(.drawStart(startPoint))
        }
    }
    
    // MARK: - Annotation Management Tests
    
    func testAnnotationCreation() {
        // Test that annotations are properly created and managed
        let arrowTool = MockArrowTool()
        annotationEngine.registerTool(arrowTool)
        annotationEngine.selectTool(.arrow)
        
        let annotation = Annotation(
            id: UUID(),
            type: .arrow,
            properties: ArrowProperties(color: .blue, thickness: 2.0),
            geometry: ArrowGeometry(startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 100, y: 100)),
            timestamp: Date()
        )
        
        let initialCount = annotationEngine.annotations.count
        annotationEngine.addAnnotation(annotation)
        
        XCTAssertEqual(annotationEngine.annotations.count, initialCount + 1)
        XCTAssertTrue(annotationEngine.annotations.contains { $0.id == annotation.id })
    }
    
    func testAnnotationRemoval() {
        // Test that annotations can be removed
        let annotation = Annotation(
            id: UUID(),
            type: .arrow,
            properties: ArrowProperties(color: .blue, thickness: 2.0),
            geometry: ArrowGeometry(startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 100, y: 100)),
            timestamp: Date()
        )
        
        annotationEngine.addAnnotation(annotation)
        let countAfterAdd = annotationEngine.annotations.count
        
        annotationEngine.removeAnnotation(annotation.id)
        
        XCTAssertEqual(annotationEngine.annotations.count, countAfterAdd - 1)
        XCTAssertFalse(annotationEngine.annotations.contains { $0.id == annotation.id })
    }
    
    // MARK: - State Management Tests
    
    func testAnnotationEngineInitialization() {
        // Test that AnnotationEngine initializes with proper default state
        let engine = AnnotationEngine()
        
        XCTAssertNotNil(engine.toolState)
        XCTAssertNotNil(engine.history)
        XCTAssertEqual(engine.annotations.count, 0)
        XCTAssertNil(engine.selectedTool)
    }
    
    func testEngineStateReset() {
        // Test that engine state can be reset properly
        let arrowTool = ArrowTool()
        annotationEngine.registerTool(arrowTool)
        annotationEngine.selectTool(.arrow)
        
        let annotation = Annotation(
            id: UUID(),
            type: .arrow,
            properties: ArrowProperties(color: .blue, thickness: 2.0),
            geometry: ArrowGeometry(startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 100, y: 100)),
            timestamp: Date()
        )
        annotationEngine.addAnnotation(annotation)
        
        // Reset state
        annotationEngine.reset()
        
        XCTAssertEqual(annotationEngine.annotations.count, 0)
        XCTAssertNil(annotationEngine.selectedTool)
    }
    
    // MARK: - Rectangle Tool Tests
    
    func testRectangleToolCreation() {
        // Test that RectangleTool can be created and registered
        let rectangleTool = RectangleTool()
        annotationEngine.registerTool(rectangleTool)
        
        let retrievedTool = annotationEngine.getTool(for: .rectangle)
        XCTAssertNotNil(retrievedTool)
        XCTAssertTrue(retrievedTool is RectangleTool)
        XCTAssertEqual(retrievedTool?.type, .rectangle)
    }
    
    func testRectangleAnnotationCreation() {
        // Test that RectangleTool creates proper annotations
        let rectangleTool = RectangleTool()
        annotationEngine.registerTool(rectangleTool)
        annotationEngine.selectTool(.rectangle)
        
        let startPoint = CGPoint(x: 50, y: 50)
        let endPoint = CGPoint(x: 150, y: 100)
        
        annotationEngine.handleCanvasEvent(.drawStart(startPoint))
        let annotation = annotationEngine.handleCanvasEvent(.drawEnd(endPoint))
        
        XCTAssertNotNil(annotation)
        XCTAssertEqual(annotation?.type, .rectangle)
        
        guard let rectGeometry = annotation?.geometry as? RectangleGeometry else {
            XCTFail("Expected RectangleGeometry")
            return
        }
        
        XCTAssertEqual(rectGeometry.rect.minX, 50)
        XCTAssertEqual(rectGeometry.rect.minY, 50)
        XCTAssertEqual(rectGeometry.rect.width, 100)
        XCTAssertEqual(rectGeometry.rect.height, 50)
    }
    
    func testRectanglePropertiesConfiguration() {
        // Test that rectangle properties are properly configured
        let rectangleTool = RectangleTool()
        
        let toolState = AnnotationToolState()
        toolState.color = .red
        toolState.thickness = 3.0
        
        rectangleTool.configure(with: toolState)
        
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: 100, y: 100)
        
        let annotation = rectangleTool.handleDrawEnd(endPoint, state: toolState)
        
        XCTAssertNotNil(annotation)
        guard let properties = annotation?.properties as? RectangleProperties else {
            XCTFail("Expected RectangleProperties")
            return
        }
        
        XCTAssertEqual(properties.color, .red)
        XCTAssertEqual(properties.thickness, 3.0)
    }
    
    // MARK: - Highlight Tool Tests
    
    func testHighlightToolCreation() {
        // Test that HighlightTool can be created and registered
        let highlightTool = HighlightTool()
        annotationEngine.registerTool(highlightTool)
        
        let retrievedTool = annotationEngine.getTool(for: .highlight)
        XCTAssertNotNil(retrievedTool)
        XCTAssertTrue(retrievedTool is HighlightTool)
        XCTAssertEqual(retrievedTool?.type, .highlight)
    }
    
    func testHighlightAnnotationCreation() {
        // Test that HighlightTool creates proper annotations
        let highlightTool = HighlightTool()
        annotationEngine.registerTool(highlightTool)
        annotationEngine.selectTool(.highlight)
        
        let startPoint = CGPoint(x: 25, y: 25)
        let endPoint = CGPoint(x: 200, y: 75)
        
        annotationEngine.handleCanvasEvent(.drawStart(startPoint))
        let annotation = annotationEngine.handleCanvasEvent(.drawEnd(endPoint))
        
        XCTAssertNotNil(annotation)
        XCTAssertEqual(annotation?.type, .highlight)
        
        guard let highlightGeometry = annotation?.geometry as? HighlightGeometry else {
            XCTFail("Expected HighlightGeometry")
            return
        }
        
        XCTAssertEqual(highlightGeometry.rect.minX, 25)
        XCTAssertEqual(highlightGeometry.rect.minY, 25)
        XCTAssertEqual(highlightGeometry.rect.width, 175)
        XCTAssertEqual(highlightGeometry.rect.height, 50)
    }
    
    func testHighlightPropertiesConfiguration() {
        // Test that highlight properties are properly configured
        let highlightTool = HighlightTool()
        
        let toolState = AnnotationToolState()
        toolState.color = .yellow
        
        highlightTool.configure(with: toolState)
        
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: 100, y: 50)
        
        let annotation = highlightTool.handleDrawEnd(endPoint, state: toolState)
        
        XCTAssertNotNil(annotation)
        guard let properties = annotation?.properties as? HighlightProperties else {
            XCTFail("Expected HighlightProperties")
            return
        }
        
        XCTAssertEqual(properties.color, .yellow)
        XCTAssertEqual(properties.opacity, 0.4) // Default opacity
    }
    
    // MARK: - Blur Tool Tests
    
    func testBlurToolCreation() {
        // Test that BlurTool can be created and registered
        let blurTool = BlurTool()
        annotationEngine.registerTool(blurTool)
        
        let retrievedTool = annotationEngine.getTool(for: .blur)
        XCTAssertNotNil(retrievedTool)
        XCTAssertTrue(retrievedTool is BlurTool)
        XCTAssertEqual(retrievedTool?.type, .blur)
    }
    
    func testBlurAnnotationCreation() {
        // Test that BlurTool creates proper annotations
        let blurTool = BlurTool()
        annotationEngine.registerTool(blurTool)
        annotationEngine.selectTool(.blur)
        
        let startPoint = CGPoint(x: 10, y: 10)
        let endPoint = CGPoint(x: 60, y: 40)
        
        annotationEngine.handleCanvasEvent(.drawStart(startPoint))
        let annotation = annotationEngine.handleCanvasEvent(.drawEnd(endPoint))
        
        XCTAssertNotNil(annotation)
        XCTAssertEqual(annotation?.type, .blur)
        
        guard let blurGeometry = annotation?.geometry as? BlurGeometry else {
            XCTFail("Expected BlurGeometry")
            return
        }
        
        XCTAssertEqual(blurGeometry.rect.minX, 10)
        XCTAssertEqual(blurGeometry.rect.minY, 10)
        XCTAssertEqual(blurGeometry.rect.width, 50)
        XCTAssertEqual(blurGeometry.rect.height, 30)
    }
    
    func testBlurPropertiesConfiguration() {
        // Test that blur properties are properly configured
        let blurTool = BlurTool()
        
        let toolState = AnnotationToolState()
        blurTool.configure(with: toolState)
        
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: 80, y: 80)
        
        let annotation = blurTool.handleDrawEnd(endPoint, state: toolState)
        
        XCTAssertNotNil(annotation)
        guard let properties = annotation?.properties as? BlurProperties else {
            XCTFail("Expected BlurProperties")
            return
        }
        
        XCTAssertEqual(properties.blurRadius, 10.0) // Default blur radius
    }
    
    // MARK: - Tool Hit Testing
    
    func testRectangleToolHitTesting() {
        // Test that rectangle tool correctly performs hit testing
        let rectangleTool = RectangleTool()
        
        let annotation = Annotation(
            type: .rectangle,
            properties: RectangleProperties(),
            geometry: RectangleGeometry(rect: CGRect(x: 50, y: 50, width: 100, height: 50))
        )
        
        // Point inside rectangle
        XCTAssertTrue(rectangleTool.hitTest(CGPoint(x: 75, y: 75), annotation: annotation))
        
        // Point outside rectangle
        XCTAssertFalse(rectangleTool.hitTest(CGPoint(x: 25, y: 25), annotation: annotation))
        
        // Point on edge
        XCTAssertTrue(rectangleTool.hitTest(CGPoint(x: 50, y: 75), annotation: annotation))
    }
    
    func testHighlightToolHitTesting() {
        // Test that highlight tool correctly performs hit testing
        let highlightTool = HighlightTool()
        
        let annotation = Annotation(
            type: .highlight,
            properties: HighlightProperties(),
            geometry: HighlightGeometry(rect: CGRect(x: 20, y: 20, width: 80, height: 40))
        )
        
        // Point inside highlight area
        XCTAssertTrue(highlightTool.hitTest(CGPoint(x: 50, y: 40), annotation: annotation))
        
        // Point outside highlight area
        XCTAssertFalse(highlightTool.hitTest(CGPoint(x: 10, y: 10), annotation: annotation))
    }
    
    func testBlurToolHitTesting() {
        // Test that blur tool correctly performs hit testing
        let blurTool = BlurTool()
        
        let annotation = Annotation(
            type: .blur,
            properties: BlurProperties(),
            geometry: BlurGeometry(rect: CGRect(x: 30, y: 30, width: 60, height: 60))
        )
        
        // Point inside blur area
        XCTAssertTrue(blurTool.hitTest(CGPoint(x: 60, y: 60), annotation: annotation))
        
        // Point outside blur area
        XCTAssertFalse(blurTool.hitTest(CGPoint(x: 100, y: 100), annotation: annotation))
    }
}

// MARK: - Mock Classes

class MockAnnotationToolState: ObservableObject {
    @Published var selectedTool: AnnotationType = .arrow
    @Published var color: Color = .black
    @Published var thickness: Double = 2.0
    @Published var fontSize: Double = 14.0
}

class MockAnnotationHistory: ObservableObject {
    @Published var annotations: [Annotation] = []
    private var undoStack: [AnnotationCommand] = []
    private var redoStack: [AnnotationCommand] = []
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
}

class MockArrowTool: AnnotationTool {
    let type: AnnotationType = .arrow
    var isActive: Bool = false
    
    var drawStartCalled = false
    var drawUpdateCalled = false
    var drawEndCalled = false
    
    var lastStartPoint: CGPoint?
    var lastUpdatePoint: CGPoint?
    var lastEndPoint: CGPoint?
    
    func handleDrawStart(_ point: CGPoint, state: AnnotationToolState) {
        drawStartCalled = true
        lastStartPoint = point
    }
    
    func handleDrawUpdate(_ point: CGPoint, state: AnnotationToolState) {
        drawUpdateCalled = true
        lastUpdatePoint = point
    }
    
    func handleDrawEnd(_ point: CGPoint, state: AnnotationToolState) -> Annotation? {
        drawEndCalled = true
        lastEndPoint = point
        return nil // Mock implementation
    }
    
    func render(_ annotation: Annotation, in context: GraphicsContext) {
        // Mock implementation
    }
    
    func configure(with state: AnnotationToolState) {
        // Mock implementation
    }
    
    func hitTest(_ point: CGPoint, annotation: Annotation) -> Bool {
        return false // Mock implementation
    }
    
    func activate() {
        isActive = true
    }
    
    func deactivate() {
        isActive = false
    }
}
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
}
import XCTest
import SwiftUI
@testable import screenit

@MainActor
final class TextToolTests: XCTestCase {
    
    var textTool: TextTool!
    var toolState: AnnotationToolState!
    
    override func setUp() async throws {
        textTool = TextTool()
        toolState = AnnotationToolState()
        // Set up default text properties
        toolState.textProperties.fontSize = 16.0
        toolState.textProperties.color = .black
        toolState.textProperties.fontWeight = .regular
    }
    
    override func tearDown() async throws {
        textTool = nil
        toolState = nil
    }
    
    // MARK: - Tool Configuration Tests
    
    func testTextToolInitialization() {
        XCTAssertEqual(textTool.type, .text)
        XCTAssertFalse(textTool.isActive)
        XCTAssertFalse(textTool.isEditing)
        XCTAssertEqual(textTool.currentText, "")
    }
    
    func testTextToolActivation() {
        textTool.activate()
        XCTAssertTrue(textTool.isActive)
        
        textTool.deactivate()
        XCTAssertFalse(textTool.isActive)
    }
    
    func testTextToolConfiguration() {
        toolState.textProperties.fontSize = 20.0
        toolState.textProperties.color = .red
        toolState.textProperties.fontWeight = .bold
        
        textTool.configure(with: toolState)
        
        // Configuration should be stored and used for text creation
        XCTAssertNoThrow(textTool.configure(with: toolState))
    }
    
    // MARK: - Text Input Tests
    
    func testTextInputHandling() {
        let testText = "Hello World"
        
        textTool.updateTextInput(testText)
        XCTAssertEqual(textTool.currentText, testText)
        
        // Test text clearing
        textTool.updateTextInput("")
        XCTAssertEqual(textTool.currentText, "")
    }
    
    func testMultilineTextInput() {
        let multilineText = "Line 1\nLine 2\nLine 3"
        
        textTool.updateTextInput(multilineText)
        XCTAssertEqual(textTool.currentText, multilineText)
        XCTAssertTrue(textTool.currentText.contains("\n"))
    }
    
    func testTextInputValidation() {
        // Test empty text
        textTool.updateTextInput("")
        let emptyAnnotation = textTool.finishTextEditing()
        XCTAssertNil(emptyAnnotation)
        
        // Test whitespace only
        textTool.updateTextInput("   \n\t  ")
        let whitespaceAnnotation = textTool.finishTextEditing()
        XCTAssertNil(whitespaceAnnotation)
        
        // Test valid text
        textTool.updateTextInput("Valid text")
        let validAnnotation = textTool.finishTextEditing()
        XCTAssertNotNil(validAnnotation)
    }
    
    // MARK: - Text Editing Lifecycle Tests
    
    func testTextEditingLifecycle() {
        let startPoint = CGPoint(x: 100, y: 100)
        
        // Start text editing
        textTool.handleDrawStart(startPoint, state: toolState)
        XCTAssertTrue(textTool.isEditing)
        
        // Update text
        textTool.updateTextInput("Test text")
        XCTAssertEqual(textTool.currentText, "Test text")
        
        // End editing
        let annotation = textTool.handleDrawEnd(startPoint, state: toolState)
        XCTAssertNotNil(annotation)
        XCTAssertFalse(textTool.isEditing)
        XCTAssertEqual(textTool.currentText, "")
    }
    
    func testTextEditingCancellation() {
        let startPoint = CGPoint(x: 100, y: 100)
        
        textTool.handleDrawStart(startPoint, state: toolState)
        textTool.updateTextInput("Some text")
        
        // Cancel editing by calling handleDrawEnd with empty text
        textTool.updateTextInput("")
        let annotation = textTool.handleDrawEnd(startPoint, state: toolState)
        
        XCTAssertNil(annotation)
        XCTAssertFalse(textTool.isEditing)
    }
    
    // MARK: - Annotation Creation Tests
    
    func testTextAnnotationCreation() {
        let position = CGPoint(x: 50, y: 75)
        let text = "Test Annotation"
        
        textTool.handleDrawStart(position, state: toolState)
        textTool.updateTextInput(text)
        
        let annotation = textTool.handleDrawEnd(position, state: toolState)
        
        XCTAssertNotNil(annotation)
        XCTAssertEqual(annotation?.type, .text)
        
        guard let textProperties = annotation?.properties as? TextProperties else {
            XCTFail("Annotation should have TextProperties")
            return
        }
        
        XCTAssertEqual(textProperties.text, text)
        XCTAssertEqual(textProperties.fontSize, toolState.textProperties.fontSize)
        XCTAssertEqual(textProperties.color, toolState.textProperties.color)
        XCTAssertEqual(textProperties.fontWeight, toolState.textProperties.fontWeight)
        
        guard let geometry = annotation?.geometry as? TextGeometry else {
            XCTFail("Annotation should have TextGeometry")
            return
        }
        
        XCTAssertEqual(geometry.position, position)
        XCTAssertGreaterThan(geometry.size.width, 0)
        XCTAssertGreaterThan(geometry.size.height, 0)
    }
    
    func testTextAnnotationWithCustomProperties() {
        let position = CGPoint(x: 100, y: 200)
        let text = "Custom Text"
        
        // Set custom properties
        toolState.textProperties.fontSize = 24.0
        toolState.textProperties.color = .blue
        toolState.textProperties.fontWeight = .bold
        toolState.textProperties.backgroundColor = .yellow
        
        textTool.configure(with: toolState)
        textTool.handleDrawStart(position, state: toolState)
        textTool.updateTextInput(text)
        
        let annotation = textTool.handleDrawEnd(position, state: toolState)
        
        guard let textProperties = annotation?.properties as? TextProperties else {
            XCTFail("Annotation should have TextProperties")
            return
        }
        
        XCTAssertEqual(textProperties.fontSize, 24.0)
        XCTAssertEqual(textProperties.color, .blue)
        XCTAssertEqual(textProperties.fontWeight, .bold)
        XCTAssertEqual(textProperties.backgroundColor, .yellow)
    }
    
    // MARK: - Text Size Calculation Tests
    
    func testTextSizeCalculation() {
        let shortText = "Hi"
        let longText = "This is a much longer text string"
        let multilineText = "Line 1\nLine 2\nLine 3"
        
        toolState.textProperties.fontSize = 16.0
        
        textTool.handleDrawStart(CGPoint.zero, state: toolState)
        
        // Test short text
        textTool.updateTextInput(shortText)
        let shortAnnotation = textTool.handleDrawEnd(CGPoint.zero, state: toolState)
        let shortGeometry = shortAnnotation?.geometry as? TextGeometry
        
        // Test long text
        textTool.handleDrawStart(CGPoint.zero, state: toolState)
        textTool.updateTextInput(longText)
        let longAnnotation = textTool.handleDrawEnd(CGPoint.zero, state: toolState)
        let longGeometry = longAnnotation?.geometry as? TextGeometry
        
        // Test multiline text
        textTool.handleDrawStart(CGPoint.zero, state: toolState)
        textTool.updateTextInput(multilineText)
        let multilineAnnotation = textTool.handleDrawEnd(CGPoint.zero, state: toolState)
        let multilineGeometry = multilineAnnotation?.geometry as? TextGeometry
        
        XCTAssertNotNil(shortGeometry)
        XCTAssertNotNil(longGeometry)
        XCTAssertNotNil(multilineGeometry)
        
        // Long text should be wider than short text
        if let short = shortGeometry, let long = longGeometry {
            XCTAssertLessThan(short.size.width, long.size.width)
        }
        
        // Multiline text should be taller than single line
        if let short = shortGeometry, let multiline = multilineGeometry {
            XCTAssertLessThan(short.size.height, multiline.size.height)
        }
    }
    
    // MARK: - Hit Testing Tests
    
    func testTextHitTesting() {
        let position = CGPoint(x: 100, y: 100)
        let text = "Hit Test"
        
        textTool.handleDrawStart(position, state: toolState)
        textTool.updateTextInput(text)
        
        guard let annotation = textTool.handleDrawEnd(position, state: toolState) else {
            XCTFail("Should create annotation")
            return
        }
        
        // Test hit within text bounds
        let hitPoint = CGPoint(x: 105, y: 105)
        XCTAssertTrue(textTool.hitTest(hitPoint, annotation: annotation))
        
        // Test miss outside text bounds
        let missPoint = CGPoint(x: 300, y: 300)
        XCTAssertFalse(textTool.hitTest(missPoint, annotation: annotation))
        
        // Test edge case - point on border (should be expanded)
        if let geometry = annotation.geometry as? TextGeometry {
            let edgePoint = CGPoint(
                x: geometry.position.x + geometry.size.width,
                y: geometry.position.y + geometry.size.height
            )
            XCTAssertTrue(textTool.hitTest(edgePoint, annotation: annotation))
        }
    }
    
    // MARK: - Rendering Tests
    
    func testTextRenderingSetup() {
        let position = CGPoint(x: 50, y: 50)
        let text = "Render Test"
        
        toolState.textProperties.fontSize = 18.0
        toolState.textProperties.color = .red
        toolState.textProperties.backgroundColor = .white
        
        textTool.handleDrawStart(position, state: toolState)
        textTool.updateTextInput(text)
        
        let annotation = textTool.handleDrawEnd(position, state: toolState)
        XCTAssertNotNil(annotation)
        
        // Test that rendering doesn't crash
        let mockContext = MockGraphicsContext()
        XCTAssertNoThrow(textTool.render(annotation!, in: mockContext))
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidAnnotationHandling() {
        // Create invalid annotation with wrong properties type
        let invalidAnnotation = Annotation(
            type: .text,
            properties: ArrowProperties(), // Wrong type
            geometry: TextGeometry(position: CGPoint.zero, size: CGSize.zero)
        )
        
        let mockContext = MockGraphicsContext()
        XCTAssertNoThrow(textTool.render(invalidAnnotation, in: mockContext))
        XCTAssertFalse(textTool.hitTest(CGPoint.zero, annotation: invalidAnnotation))
    }
    
    // MARK: - Integration Tests
    
    func testTextToolWithAnnotationEngine() {
        let engine = AnnotationEngine()
        engine.selectTool(.text)
        
        XCTAssertEqual(engine.selectedTool?.type, .text)
        XCTAssertTrue(engine.selectedTool is TextTool)
        
        // Test canvas event handling
        let startEvent = CanvasEvent.drawStart(CGPoint(x: 100, y: 100))
        let endEvent = CanvasEvent.drawEnd(CGPoint(x: 100, y: 100))
        
        engine.handleCanvasEvent(startEvent)
        
        // Simulate text input
        if let selectedTextTool = engine.selectedTool as? TextTool {
            selectedTextTool.updateTextInput("Integration Test")
        }
        
        engine.handleCanvasEvent(endEvent)
        
        XCTAssertEqual(engine.annotations.count, 1)
        XCTAssertEqual(engine.annotations.first?.type, .text)
    }
}

// MARK: - Mock Classes

class MockGraphicsContext: GraphicsContext {
    // Minimal mock implementation for testing
}
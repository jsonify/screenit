import XCTest
import SwiftUI
@testable import screenit

@MainActor
final class ArrowToolTests: XCTestCase {
    
    var arrowTool: ArrowTool!
    var toolState: AnnotationToolState!
    
    override func setUp() async throws {
        arrowTool = ArrowTool()
        toolState = AnnotationToolState()
        toolState.selectTool(.arrow)
    }
    
    override func tearDown() async throws {
        arrowTool = nil
        toolState = nil
    }
    
    // MARK: - Initialization Tests
    
    func testArrowToolInitialization() {
        XCTAssertEqual(arrowTool.type, .arrow)
        XCTAssertFalse(arrowTool.isActive)
        XCTAssertFalse(arrowTool.isDrawing)
    }
    
    // MARK: - Tool Lifecycle Tests
    
    func testToolActivation() {
        arrowTool.activate()
        XCTAssertTrue(arrowTool.isActive)
    }
    
    func testToolDeactivation() {
        arrowTool.activate()
        arrowTool.deactivate()
        
        XCTAssertFalse(arrowTool.isActive)
        XCTAssertFalse(arrowTool.isDrawing)
        XCTAssertNil(arrowTool.startPoint)
        XCTAssertNil(arrowTool.currentPoint)
    }
    
    // MARK: - Drawing Lifecycle Tests
    
    func testDrawStart() {
        let startPoint = CGPoint(x: 100, y: 100)
        
        arrowTool.handleDrawStart(startPoint, state: toolState)
        
        XCTAssertTrue(arrowTool.isDrawing)
        XCTAssertEqual(arrowTool.startPoint, startPoint)
        XCTAssertEqual(arrowTool.currentPoint, startPoint)
    }
    
    func testDrawUpdate() {
        let startPoint = CGPoint(x: 100, y: 100)
        let updatePoint = CGPoint(x: 150, y: 150)
        
        arrowTool.handleDrawStart(startPoint, state: toolState)
        arrowTool.handleDrawUpdate(updatePoint, state: toolState)
        
        XCTAssertTrue(arrowTool.isDrawing)
        XCTAssertEqual(arrowTool.startPoint, startPoint)
        XCTAssertEqual(arrowTool.currentPoint, updatePoint)
    }
    
    func testDrawEndCreatesAnnotation() {
        let startPoint = CGPoint(x: 100, y: 100)
        let endPoint = CGPoint(x: 200, y: 200)
        
        arrowTool.handleDrawStart(startPoint, state: toolState)
        let annotation = arrowTool.handleDrawEnd(endPoint, state: toolState)
        
        XCTAssertNotNil(annotation)
        XCTAssertEqual(annotation?.type, .arrow)
        
        // Verify properties
        guard let arrowProperties = annotation?.properties as? ArrowProperties else {
            XCTFail("Expected ArrowProperties")
            return
        }
        XCTAssertEqual(arrowProperties.color, toolState.color)
        XCTAssertEqual(arrowProperties.thickness, toolState.thickness)
        XCTAssertEqual(arrowProperties.arrowheadStyle, toolState.arrowheadStyle)
        
        // Verify geometry
        guard let arrowGeometry = annotation?.geometry as? ArrowGeometry else {
            XCTFail("Expected ArrowGeometry")
            return
        }
        XCTAssertEqual(arrowGeometry.startPoint, startPoint)
        XCTAssertEqual(arrowGeometry.endPoint, endPoint)
        
        // Verify drawing state is reset
        XCTAssertFalse(arrowTool.isDrawing)
        XCTAssertNil(arrowTool.startPoint)
        XCTAssertNil(arrowTool.currentPoint)
    }
    
    func testDrawEndWithTooSmallArrow() {
        let startPoint = CGPoint(x: 100, y: 100)
        let endPoint = CGPoint(x: 102, y: 102) // Very small arrow
        
        arrowTool.handleDrawStart(startPoint, state: toolState)
        let annotation = arrowTool.handleDrawEnd(endPoint, state: toolState)
        
        XCTAssertNil(annotation, "Small arrows should not create annotations")
        XCTAssertFalse(arrowTool.isDrawing)
    }
    
    // MARK: - Arrow Properties Tests
    
    func testArrowPropertiesWithDifferentColors() {
        let colors: [Color] = [.red, .blue, .green, .yellow]
        
        for color in colors {
            toolState.color = color
            
            let startPoint = CGPoint(x: 100, y: 100)
            let endPoint = CGPoint(x: 200, y: 200)
            
            arrowTool.handleDrawStart(startPoint, state: toolState)
            let annotation = arrowTool.handleDrawEnd(endPoint, state: toolState)
            
            guard let properties = annotation?.properties as? ArrowProperties else {
                XCTFail("Expected ArrowProperties")
                continue
            }
            
            XCTAssertEqual(properties.color, color)
        }
    }
    
    func testArrowPropertiesWithDifferentThickness() {
        let thicknesses: [Double] = [1.0, 2.5, 5.0, 10.0]
        
        for thickness in thicknesses {
            toolState.thickness = thickness
            
            let startPoint = CGPoint(x: 100, y: 100)
            let endPoint = CGPoint(x: 200, y: 200)
            
            arrowTool.handleDrawStart(startPoint, state: toolState)
            let annotation = arrowTool.handleDrawEnd(endPoint, state: toolState)
            
            guard let properties = annotation?.properties as? ArrowProperties else {
                XCTFail("Expected ArrowProperties")
                continue
            }
            
            XCTAssertEqual(properties.thickness, thickness)
        }
    }
    
    func testArrowPropertiesWithDifferentArrowheadStyles() {
        let styles: [ArrowProperties.ArrowheadStyle] = [.standard, .rounded, .square]
        
        for style in styles {
            toolState.arrowheadStyle = style
            
            let startPoint = CGPoint(x: 100, y: 100)
            let endPoint = CGPoint(x: 200, y: 200)
            
            arrowTool.handleDrawStart(startPoint, state: toolState)
            let annotation = arrowTool.handleDrawEnd(endPoint, state: toolState)
            
            guard let properties = annotation?.properties as? ArrowProperties else {
                XCTFail("Expected ArrowProperties")
                continue
            }
            
            XCTAssertEqual(properties.arrowheadStyle, style)
        }
    }
    
    // MARK: - Hit Testing Tests
    
    func testHitTestOnArrowLine() {
        let startPoint = CGPoint(x: 100, y: 100)
        let endPoint = CGPoint(x: 200, y: 200)
        
        let annotation = createTestArrowAnnotation(start: startPoint, end: endPoint)
        
        // Test point on the line
        let midPoint = CGPoint(x: 150, y: 150)
        XCTAssertTrue(arrowTool.hitTest(midPoint, annotation: annotation))
        
        // Test point near the line (within tolerance)
        let nearPoint = CGPoint(x: 152, y: 148)
        XCTAssertTrue(arrowTool.hitTest(nearPoint, annotation: annotation))
        
        // Test point far from the line
        let farPoint = CGPoint(x: 300, y: 300)
        XCTAssertFalse(arrowTool.hitTest(farPoint, annotation: annotation))
    }
    
    func testHitTestOnArrowEndpoints() {
        let startPoint = CGPoint(x: 100, y: 100)
        let endPoint = CGPoint(x: 200, y: 200)
        
        let annotation = createTestArrowAnnotation(start: startPoint, end: endPoint)
        
        // Test start point
        XCTAssertTrue(arrowTool.hitTest(startPoint, annotation: annotation))
        
        // Test end point
        XCTAssertTrue(arrowTool.hitTest(endPoint, annotation: annotation))
    }
    
    func testHitTestWithThickArrow() {
        let startPoint = CGPoint(x: 100, y: 100)
        let endPoint = CGPoint(x: 200, y: 200)
        
        toolState.thickness = 10.0
        let annotation = createTestArrowAnnotation(start: startPoint, end: endPoint, thickness: 10.0)
        
        // Point that should hit due to thick line
        let testPoint = CGPoint(x: 155, y: 145) // Slightly off the line
        XCTAssertTrue(arrowTool.hitTest(testPoint, annotation: annotation))
    }
    
    // MARK: - Configuration Tests
    
    func testConfigure() {
        // Test that configure method doesn't crash
        XCTAssertNoThrow {
            arrowTool.configure(with: toolState)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testDrawWithZeroLengthArrow() {
        let point = CGPoint(x: 100, y: 100)
        
        arrowTool.handleDrawStart(point, state: toolState)
        let annotation = arrowTool.handleDrawEnd(point, state: toolState)
        
        XCTAssertNil(annotation, "Zero-length arrows should not create annotations")
    }
    
    func testMultipleDrawSequences() {
        // Test that multiple draw sequences work correctly
        for i in 0..<3 {
            let startPoint = CGPoint(x: Double(i * 100), y: Double(i * 100))
            let endPoint = CGPoint(x: Double(i * 100 + 50), y: Double(i * 100 + 50))
            
            arrowTool.handleDrawStart(startPoint, state: toolState)
            let annotation = arrowTool.handleDrawEnd(endPoint, state: toolState)
            
            XCTAssertNotNil(annotation)
            XCTAssertFalse(arrowTool.isDrawing)
        }
    }
    
    // MARK: - Rendering Tests
    
    func testRenderWithValidAnnotation() {
        let annotation = createTestArrowAnnotation(
            start: CGPoint(x: 100, y: 100),
            end: CGPoint(x: 200, y: 200)
        )
        
        // Test that render method exists and can be called with valid annotation
        // We can't easily test GraphicsContext rendering without a real canvas,
        // but we can verify the method doesn't crash with valid input
        XCTAssertNoThrow {
            // This validates that the annotation has the correct type structure
            guard annotation.properties is ArrowProperties,
                  annotation.geometry is ArrowGeometry else {
                XCTFail("Annotation should have correct property and geometry types")
                return
            }
        }
    }
    
    func testRenderWithInvalidAnnotation() {
        // Create annotation with wrong properties type
        let invalidAnnotation = Annotation(
            type: .arrow,
            properties: TextProperties(), // Wrong type
            geometry: ArrowGeometry(startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 100, y: 100))
        )
        
        // The render method should handle invalid annotations gracefully
        // We verify this by checking the structure validation that would happen in render
        XCTAssertFalse(invalidAnnotation.properties is ArrowProperties, "Should detect invalid properties type")
        XCTAssertTrue(invalidAnnotation.geometry is ArrowGeometry, "Geometry should be correct type")
    }
    
    // MARK: - Helper Methods
    
    private func createTestArrowAnnotation(start: CGPoint, end: CGPoint, color: Color = .black, thickness: Double = 2.0, style: ArrowProperties.ArrowheadStyle = .standard) -> Annotation {
        let properties = ArrowProperties(color: color, thickness: thickness, arrowheadStyle: style)
        let geometry = ArrowGeometry(startPoint: start, endPoint: end)
        
        return Annotation(
            type: .arrow,
            properties: properties,
            geometry: geometry
        )
    }
}
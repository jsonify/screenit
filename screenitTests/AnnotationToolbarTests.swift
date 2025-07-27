import XCTest
import SwiftUI
@testable import screenit

final class AnnotationToolbarTests: XCTestCase {
  
  func testAnnotationToolbarInitialization() {
    let toolbar = AnnotationToolbar(
      selectedTool: .constant(.arrow),
      selectedColor: .constant(.red),
      onToolChange: { _ in },
      onColorChange: { _ in }
    )
    
    XCTAssertNotNil(toolbar)
  }
  
  func testToolSelection() {
    var currentTool: AnnotationType = .arrow
    let toolbar = AnnotationToolbar(
      selectedTool: .constant(currentTool),
      selectedColor: .constant(.red),
      onToolChange: { tool in
        currentTool = tool
      },
      onColorChange: { _ in }
    )
    
    XCTAssertEqual(currentTool, .arrow)
  }
  
  func testColorSelection() {
    var currentColor: Color = .red
    let toolbar = AnnotationToolbar(
      selectedTool: .constant(.arrow),
      selectedColor: .constant(currentColor),
      onToolChange: { _ in },
      onColorChange: { color in
        currentColor = color
      }
    )
    
    XCTAssertEqual(currentColor, .red)
  }
  
  func testPredefinedColors() {
    let predefinedColors = AnnotationToolbar.predefinedColors
    
    XCTAssertEqual(predefinedColors.count, 6)
    XCTAssertTrue(predefinedColors.contains(.red))
    XCTAssertTrue(predefinedColors.contains(.blue))
    XCTAssertTrue(predefinedColors.contains(.green))
    XCTAssertTrue(predefinedColors.contains(.yellow))
    XCTAssertTrue(predefinedColors.contains(.orange))
    XCTAssertTrue(predefinedColors.contains(.purple))
  }
  
  func testAllToolTypesRepresented() {
    let allTools: [AnnotationType] = [.arrow, .text, .rectangle, .highlight, .blur]
    
    for tool in allTools {
      XCTAssertNotNil(tool.icon, "Tool \(tool) should have an icon")
      XCTAssertNotNil(tool.name, "Tool \(tool) should have a name")
      XCTAssertNotNil(tool.keyboardShortcut, "Tool \(tool) should have a keyboard shortcut")
    }
  }
  
  func testKeyboardShortcuts() {
    XCTAssertEqual(AnnotationType.arrow.keyboardShortcut, "A")
    XCTAssertEqual(AnnotationType.text.keyboardShortcut, "T")
    XCTAssertEqual(AnnotationType.rectangle.keyboardShortcut, "R")
    XCTAssertEqual(AnnotationType.highlight.keyboardShortcut, "H")
    XCTAssertEqual(AnnotationType.blur.keyboardShortcut, "B")
  }
  
  func testToolIcons() {
    XCTAssertEqual(AnnotationType.arrow.icon, "arrow.up.right")
    XCTAssertEqual(AnnotationType.text.icon, "textformat")
    XCTAssertEqual(AnnotationType.rectangle.icon, "rectangle")
    XCTAssertEqual(AnnotationType.highlight.icon, "highlighter")
    XCTAssertEqual(AnnotationType.blur.icon, "eye.slash")
  }
  
  func testToolNames() {
    XCTAssertEqual(AnnotationType.arrow.name, "Arrow")
    XCTAssertEqual(AnnotationType.text.name, "Text")
    XCTAssertEqual(AnnotationType.rectangle.name, "Rectangle")
    XCTAssertEqual(AnnotationType.highlight.name, "Highlight")
    XCTAssertEqual(AnnotationType.blur.name, "Blur")
  }
}

// Extension already added to AnnotationToolbar.swift
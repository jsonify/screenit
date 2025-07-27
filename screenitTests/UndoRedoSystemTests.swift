import XCTest
import SwiftUI
@testable import screenit

final class UndoRedoSystemTests: XCTestCase {
  
  var undoRedoManager: UndoRedoManager!
  
  override func setUp() {
    super.setUp()
    undoRedoManager = UndoRedoManager()
  }
  
  override func tearDown() {
    undoRedoManager = nil
    super.tearDown()
  }
  
  func testUndoRedoManagerInitialization() {
    XCTAssertFalse(undoRedoManager.canUndo)
    XCTAssertFalse(undoRedoManager.canRedo)
    XCTAssertEqual(undoRedoManager.historyCount, 0)
  }
  
  func testCommandExecution() {
    let mockCommand = MockAnnotationCommand()
    
    undoRedoManager.execute(mockCommand)
    
    XCTAssertTrue(mockCommand.wasExecuted)
    XCTAssertTrue(undoRedoManager.canUndo)
    XCTAssertFalse(undoRedoManager.canRedo)
    XCTAssertEqual(undoRedoManager.historyCount, 1)
  }
  
  func testUndoOperation() {
    let mockCommand = MockAnnotationCommand()
    
    undoRedoManager.execute(mockCommand)
    undoRedoManager.undo()
    
    XCTAssertTrue(mockCommand.wasUndone)
    XCTAssertFalse(undoRedoManager.canUndo)
    XCTAssertTrue(undoRedoManager.canRedo)
  }
  
  func testRedoOperation() {
    let mockCommand = MockAnnotationCommand()
    
    undoRedoManager.execute(mockCommand)
    undoRedoManager.undo()
    undoRedoManager.redo()
    
    XCTAssertEqual(mockCommand.executeCount, 2)
    XCTAssertTrue(undoRedoManager.canUndo)
    XCTAssertFalse(undoRedoManager.canRedo)
  }
  
  func testMultipleCommands() {
    let command1 = MockAnnotationCommand()
    let command2 = MockAnnotationCommand()
    let command3 = MockAnnotationCommand()
    
    undoRedoManager.execute(command1)
    undoRedoManager.execute(command2)
    undoRedoManager.execute(command3)
    
    XCTAssertEqual(undoRedoManager.historyCount, 3)
    
    undoRedoManager.undo()
    XCTAssertTrue(command3.wasUndone)
    XCTAssertFalse(command2.wasUndone)
    XCTAssertFalse(command1.wasUndone)
    
    undoRedoManager.undo()
    XCTAssertTrue(command2.wasUndone)
    
    undoRedoManager.redo()
    XCTAssertEqual(command2.executeCount, 2)
  }
  
  func testClearHistory() {
    let command1 = MockAnnotationCommand()
    let command2 = MockAnnotationCommand()
    
    undoRedoManager.execute(command1)
    undoRedoManager.execute(command2)
    
    undoRedoManager.clearHistory()
    
    XCTAssertFalse(undoRedoManager.canUndo)
    XCTAssertFalse(undoRedoManager.canRedo)
    XCTAssertEqual(undoRedoManager.historyCount, 0)
  }
  
  func testRedoStackClearedOnNewCommand() {
    let command1 = MockAnnotationCommand()
    let command2 = MockAnnotationCommand()
    let command3 = MockAnnotationCommand()
    
    undoRedoManager.execute(command1)
    undoRedoManager.execute(command2)
    undoRedoManager.undo()
    
    XCTAssertTrue(undoRedoManager.canRedo)
    
    undoRedoManager.execute(command3)
    
    XCTAssertFalse(undoRedoManager.canRedo)
  }
  
  func testUnlimitedHistory() {
    // Test with a large number of commands to ensure unlimited history
    let commandCount = 1000
    var commands: [MockAnnotationCommand] = []
    
    for _ in 0..<commandCount {
      let command = MockAnnotationCommand()
      commands.append(command)
      undoRedoManager.execute(command)
    }
    
    XCTAssertEqual(undoRedoManager.historyCount, commandCount)
    
    // Undo all commands
    for i in (0..<commandCount).reversed() {
      undoRedoManager.undo()
      XCTAssertTrue(commands[i].wasUndone)
    }
    
    XCTAssertFalse(undoRedoManager.canUndo)
    XCTAssertTrue(undoRedoManager.canRedo)
  }
  
  func testCommandFailure() {
    let failingCommand = FailingMockCommand()
    
    XCTAssertThrowsError(try undoRedoManager.executeWithError(failingCommand))
    
    XCTAssertFalse(undoRedoManager.canUndo)
    XCTAssertEqual(undoRedoManager.historyCount, 0)
  }
}

// MARK: - Mock Commands for Testing

class MockAnnotationCommand: AnnotationCommand {
  private(set) var wasExecuted = false
  private(set) var wasUndone = false
  private(set) var executeCount = 0
  
  func execute() throws {
    wasExecuted = true
    executeCount += 1
  }
  
  func undo() throws {
    wasUndone = true
  }
  
  var description: String {
    return "Mock Annotation Command"
  }
}

class FailingMockCommand: AnnotationCommand {
  func execute() throws {
    throw AnnotationError.commandExecutionFailed("Mock failure")
  }
  
  func undo() throws {
    // No-op for this mock
  }
  
  var description: String {
    return "Failing Mock Command"
  }
}

// MARK: - Annotation Command Protocol and Error

protocol AnnotationCommand: CustomStringConvertible {
  func execute() throws
  func undo() throws
}

enum AnnotationError: Error {
  case commandExecutionFailed(String)
  case undoFailed(String)
  case redoFailed(String)
}
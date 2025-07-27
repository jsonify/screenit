import Foundation
import SwiftUI
import Combine

// MARK: - Undo/Redo Manager

@MainActor
class UndoRedoManager: ObservableObject {
  
  // MARK: - Published Properties
  
  @Published private(set) var canUndo: Bool = false
  @Published private(set) var canRedo: Bool = false
  
  // MARK: - Private Properties
  
  private var undoStack: [AnnotationCommand] = []
  private var redoStack: [AnnotationCommand] = []
  private let maxHistorySize: Int
  
  // MARK: - Computed Properties
  
  var historyCount: Int {
    undoStack.count
  }
  
  var lastCommandDescription: String? {
    undoStack.last?.description
  }
  
  var nextRedoDescription: String? {
    redoStack.last?.description
  }
  
  // MARK: - Initialization
  
  init(maxHistorySize: Int = Int.max) {
    self.maxHistorySize = maxHistorySize
  }
  
  // MARK: - Command Execution
  
  func execute(_ command: AnnotationCommand) {
    do {
      try command.execute()
      addToUndoStack(command)
      clearRedoStack()
      updateCanUndoRedo()
    } catch {
      print("Command execution failed: \(error)")
    }
  }
  
  func executeWithError(_ command: AnnotationCommand) throws {
    try command.execute()
    addToUndoStack(command)
    clearRedoStack()
    updateCanUndoRedo()
  }
  
  // MARK: - Undo/Redo Operations
  
  func undo() {
    guard canUndo, let command = undoStack.popLast() else { return }
    
    do {
      try command.undo()
      redoStack.append(command)
      updateCanUndoRedo()
    } catch {
      print("Undo failed: \(error)")
      // Re-add command to undo stack if undo fails
      undoStack.append(command)
    }
  }
  
  func redo() {
    guard canRedo, let command = redoStack.popLast() else { return }
    
    do {
      try command.execute()
      undoStack.append(command)
      updateCanUndoRedo()
    } catch {
      print("Redo failed: \(error)")
      // Re-add command to redo stack if redo fails
      redoStack.append(command)
    }
  }
  
  // MARK: - History Management
  
  func clearHistory() {
    undoStack.removeAll()
    redoStack.removeAll()
    updateCanUndoRedo()
  }
  
  func clearRedoHistory() {
    clearRedoStack()
    updateCanUndoRedo()
  }
  
  // MARK: - Private Methods
  
  private func addToUndoStack(_ command: AnnotationCommand) {
    undoStack.append(command)
    
    // Maintain maximum history size
    if undoStack.count > maxHistorySize {
      undoStack.removeFirst()
    }
  }
  
  private func clearRedoStack() {
    redoStack.removeAll()
  }
  
  private func updateCanUndoRedo() {
    canUndo = !undoStack.isEmpty
    canRedo = !redoStack.isEmpty
  }
}

// MARK: - Annotation Command Protocol

protocol AnnotationCommand: CustomStringConvertible {
  @MainActor func execute() throws
  @MainActor func undo() throws
}

// MARK: - Concrete Annotation Commands

// Add Annotation Command
struct AddAnnotationCommand: AnnotationCommand {
  private let annotation: Annotation
  private weak var engine: AnnotationEngine?
  
  init(annotation: Annotation, engine: AnnotationEngine) {
    self.annotation = annotation
    self.engine = engine
  }
  
  @MainActor
  func execute() throws {
    guard let engine = engine else {
      throw AnnotationError.commandExecutionFailed("Engine reference lost")
    }
    engine.directAddAnnotation(annotation)
  }
  
  @MainActor
  func undo() throws {
    guard let engine = engine else {
      throw AnnotationError.undoFailed("Engine reference lost")
    }
    engine.directRemoveAnnotation(annotation.id)
  }
  
  var description: String {
    "Add \(annotation.type.rawValue) annotation"
  }
}

// Remove Annotation Command
struct RemoveAnnotationCommand: AnnotationCommand {
  private let annotation: Annotation
  private weak var engine: AnnotationEngine?
  
  init(annotation: Annotation, engine: AnnotationEngine) {
    self.annotation = annotation
    self.engine = engine
  }
  
  @MainActor
  func execute() throws {
    guard let engine = engine else {
      throw AnnotationError.commandExecutionFailed("Engine reference lost")
    }
    engine.directRemoveAnnotation(annotation.id)
  }
  
  @MainActor
  func undo() throws {
    guard let engine = engine else {
      throw AnnotationError.undoFailed("Engine reference lost")
    }
    engine.directAddAnnotation(annotation)
  }
  
  var description: String {
    "Remove \(annotation.type.rawValue) annotation"
  }
}

// Modify Annotation Command
struct ModifyAnnotationCommand: AnnotationCommand {
  private let annotationId: UUID
  private let oldAnnotation: Annotation
  private let newAnnotation: Annotation
  private weak var engine: AnnotationEngine?
  
  init(annotationId: UUID, oldAnnotation: Annotation, newAnnotation: Annotation, engine: AnnotationEngine) {
    self.annotationId = annotationId
    self.oldAnnotation = oldAnnotation
    self.newAnnotation = newAnnotation
    self.engine = engine
  }
  
  @MainActor
  func execute() throws {
    guard let engine = engine else {
      throw AnnotationError.commandExecutionFailed("Engine reference lost")
    }
    engine.history.modifyAnnotation(annotationId, newAnnotation: newAnnotation)
  }
  
  @MainActor
  func undo() throws {
    guard let engine = engine else {
      throw AnnotationError.undoFailed("Engine reference lost")
    }
    engine.history.modifyAnnotation(annotationId, newAnnotation: oldAnnotation)
  }
  
  var description: String {
    "Modify \(newAnnotation.type.rawValue) annotation"
  }
}

// Clear All Annotations Command
struct ClearAllAnnotationsCommand: AnnotationCommand {
  private let previousAnnotations: [Annotation]
  private weak var engine: AnnotationEngine?
  
  init(previousAnnotations: [Annotation], engine: AnnotationEngine) {
    self.previousAnnotations = previousAnnotations
    self.engine = engine
  }
  
  @MainActor
  func execute() throws {
    guard let engine = engine else {
      throw AnnotationError.commandExecutionFailed("Engine reference lost")
    }
    engine.directClearAnnotations()
  }
  
  @MainActor
  func undo() throws {
    guard let engine = engine else {
      throw AnnotationError.undoFailed("Engine reference lost")
    }
    for annotation in previousAnnotations {
      engine.directAddAnnotation(annotation)
    }
  }
  
  var description: String {
    "Clear all annotations (\(previousAnnotations.count) items)"
  }
}

// MARK: - Annotation Errors

enum AnnotationError: Error, LocalizedError {
  case commandExecutionFailed(String)
  case undoFailed(String)
  case redoFailed(String)
  case invalidAnnotation(String)
  case engineNotFound
  
  var errorDescription: String? {
    switch self {
    case .commandExecutionFailed(let message):
      return "Command execution failed: \(message)"
    case .undoFailed(let message):
      return "Undo operation failed: \(message)"
    case .redoFailed(let message):
      return "Redo operation failed: \(message)"
    case .invalidAnnotation(let message):
      return "Invalid annotation: \(message)"
    case .engineNotFound:
      return "Annotation engine not found"
    }
  }
}
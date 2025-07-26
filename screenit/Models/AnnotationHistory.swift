import Foundation
import SwiftUI

// MARK: - Command Pattern for Undo/Redo

protocol AnnotationCommand {
    func execute() -> [Annotation]
    func undo() -> [Annotation]
}

struct AddAnnotationCommand: AnnotationCommand {
    let annotation: Annotation
    let previousAnnotations: [Annotation]
    
    func execute() -> [Annotation] {
        return previousAnnotations + [annotation]
    }
    
    func undo() -> [Annotation] {
        return previousAnnotations
    }
}

struct RemoveAnnotationCommand: AnnotationCommand {
    let annotationId: UUID
    let previousAnnotations: [Annotation]
    
    func execute() -> [Annotation] {
        return previousAnnotations.filter { $0.id != annotationId }
    }
    
    func undo() -> [Annotation] {
        return previousAnnotations
    }
}

struct ModifyAnnotationCommand: AnnotationCommand {
    let annotationId: UUID
    let newAnnotation: Annotation
    let previousAnnotations: [Annotation]
    
    func execute() -> [Annotation] {
        return previousAnnotations.map { annotation in
            if annotation.id == annotationId {
                return newAnnotation
            } else {
                return annotation
            }
        }
    }
    
    func undo() -> [Annotation] {
        return previousAnnotations
    }
}

struct ClearAllAnnotationsCommand: AnnotationCommand {
    let previousAnnotations: [Annotation]
    
    func execute() -> [Annotation] {
        return []
    }
    
    func undo() -> [Annotation] {
        return previousAnnotations
    }
}

// MARK: - Annotation History Manager

@MainActor
class AnnotationHistory: ObservableObject {
    @Published private(set) var annotations: [Annotation] = []
    
    private var undoStack: [AnnotationCommand] = []
    private var redoStack: [AnnotationCommand] = []
    
    // Configuration
    private let maxHistorySize: Int = 100 // Unlimited in practice, but cap for memory management
    
    // MARK: - Public Properties
    
    var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    var canRedo: Bool {
        !redoStack.isEmpty
    }
    
    var annotationCount: Int {
        annotations.count
    }
    
    // MARK: - Command Execution
    
    func executeCommand(_ command: AnnotationCommand) {
        // Clear redo stack when new command is executed
        redoStack.removeAll()
        
        // Execute the command
        annotations = command.execute()
        
        // Add to undo stack
        undoStack.append(command)
        
        // Manage history size
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }
    }
    
    func undo() -> Bool {
        guard canUndo else { return false }
        
        let command = undoStack.removeLast()
        annotations = command.undo()
        redoStack.append(command)
        
        return true
    }
    
    func redo() -> Bool {
        guard canRedo else { return false }
        
        let command = redoStack.removeLast()
        annotations = command.execute()
        undoStack.append(command)
        
        return true
    }
    
    // MARK: - Convenience Methods
    
    func addAnnotation(_ annotation: Annotation) {
        let command = AddAnnotationCommand(
            annotation: annotation,
            previousAnnotations: annotations
        )
        executeCommand(command)
    }
    
    func removeAnnotation(_ annotationId: UUID) {
        let command = RemoveAnnotationCommand(
            annotationId: annotationId,
            previousAnnotations: annotations
        )
        executeCommand(command)
    }
    
    func modifyAnnotation(_ annotationId: UUID, newAnnotation: Annotation) {
        let command = ModifyAnnotationCommand(
            annotationId: annotationId,
            newAnnotation: newAnnotation,
            previousAnnotations: annotations
        )
        executeCommand(command)
    }
    
    func clearAllAnnotations() {
        let command = ClearAllAnnotationsCommand(
            previousAnnotations: annotations
        )
        executeCommand(command)
    }
    
    // MARK: - Query Methods
    
    func getAnnotation(by id: UUID) -> Annotation? {
        return annotations.first { $0.id == id }
    }
    
    func getAnnotations(of type: AnnotationType) -> [Annotation] {
        return annotations.filter { $0.type == type }
    }
    
    func getAnnotations(in rect: CGRect) -> [Annotation] {
        return annotations.filter { annotation in
            annotation.geometry.bounds.intersects(rect)
        }
    }
    
    func getAnnotationsAtPoint(_ point: CGPoint) -> [Annotation] {
        return annotations.filter { annotation in
            annotation.geometry.bounds.contains(point)
        }
    }
    
    // MARK: - State Management
    
    func reset() {
        annotations.removeAll()
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    func setAnnotations(_ newAnnotations: [Annotation]) {
        // This method bypasses the command system for loading saved state
        annotations = newAnnotations
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    // MARK: - History Information
    
    func getUndoDescription() -> String? {
        guard let lastCommand = undoStack.last else { return nil }
        
        switch lastCommand {
        case is AddAnnotationCommand:
            return "Add Annotation"
        case is RemoveAnnotationCommand:
            return "Remove Annotation"
        case is ModifyAnnotationCommand:
            return "Modify Annotation"
        case is ClearAllAnnotationsCommand:
            return "Clear All"
        default:
            return "Unknown Action"
        }
    }
    
    func getRedoDescription() -> String? {
        guard let nextCommand = redoStack.last else { return nil }
        
        switch nextCommand {
        case is AddAnnotationCommand:
            return "Add Annotation"
        case is RemoveAnnotationCommand:
            return "Remove Annotation"
        case is ModifyAnnotationCommand:
            return "Modify Annotation"
        case is ClearAllAnnotationsCommand:
            return "Clear All"
        default:
            return "Unknown Action"
        }
    }
}